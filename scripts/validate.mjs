#!/usr/bin/env node
/**
 * Validate Agent Skills in this repo:
 * 1. Local skill.schema.json frontmatter fields match agentskills.io (+ skills-reference)
 * 2. Each skill passes skills-reference (official reference validator)
 * 3. Each skill also satisfies local extras (string-only metadata, etc.)
 *
 * Usage:
 *   node scripts/validate.mjs              # schema sync + all skills
 *   node scripts/validate.mjs --schema     # schema sync only
 *   node scripts/validate.mjs <skill-dir>  # schema sync + one skill
 */

import { readdirSync, readFileSync, existsSync, statSync } from "node:fs";
import { basename, dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { spawnSync } from "node:child_process";

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, "..");
const SCHEMA_PATH = join(REPO_ROOT, "schemas", "skill.schema.json");
const SKILLS_DIR = join(REPO_ROOT, "skills");

/** Frontmatter fields from https://agentskills.io/specification — update when upstream changes. */
const SPEC_FIELDS = [
  "name",
  "description",
  "license",
  "compatibility",
  "metadata",
  "allowed-tools",
];

const SPEC_URL = "https://agentskills.io/specification";

function fail(msg) {
  console.error(`✗ ${msg}`);
  process.exitCode = 1;
}

function ok(msg) {
  console.log(`✓ ${msg}`);
}

function loadSchema() {
  return JSON.parse(readFileSync(SCHEMA_PATH, "utf8"));
}

function npmInstall(name) {
  const install = spawnSync(
    "npm",
    ["install", "--no-save", "--no-package-lock", name],
    {
      cwd: REPO_ROOT,
      encoding: "utf8",
      env: { ...process.env, npm_config_devdir: undefined },
    },
  );
  if (install.status !== 0) {
    fail(`Failed to install ${name}:\n${install.stderr || install.stdout}`);
    process.exit(1);
  }
}

async function loadSkillsReference() {
  try {
    return await import("skills-reference");
  } catch {
    npmInstall("skills-reference");
    const esmEntry = join(
      REPO_ROOT,
      "node_modules",
      "skills-reference",
      "dist",
      "esm",
      "index.js",
    );
    return import(pathToFileURL(esmEntry).href);
  }
}

function checkSchemaSyncBasics() {
  console.log(`\n[schema] compare ${SCHEMA_PATH} ↔ ${SPEC_URL}`);

  const schema = loadSchema();
  const props = Object.keys(schema.properties || {}).sort();
  const expected = [...SPEC_FIELDS].sort();

  if (JSON.stringify(props) !== JSON.stringify(expected)) {
    fail(
      `Local schema fields [${props.join(", ")}] != agentskills.io fields [${expected.join(", ")}]`,
    );
  } else {
    ok(`Field set matches agentskills.io: ${expected.join(", ")}`);
  }

  const required = [...(schema.required || [])].sort();
  if (JSON.stringify(required) !== JSON.stringify(["description", "name"])) {
    fail(`Local schema required fields must be [name, description], got [${required.join(", ")}]`);
  } else {
    ok("Required fields: name, description");
  }

  const name = schema.properties?.name || {};
  if (name.maxLength !== 64) fail(`name.maxLength should be 64, got ${name.maxLength}`);
  const desc = schema.properties?.description || {};
  if (desc.maxLength !== 1024) fail(`description.maxLength should be 1024, got ${desc.maxLength}`);
  const compat = schema.properties?.compatibility || {};
  if (compat.maxLength !== 500) fail(`compatibility.maxLength should be 500, got ${compat.maxLength}`);
  const meta = schema.properties?.metadata || {};
  if (meta.additionalProperties?.type !== "string") {
    fail("metadata.additionalProperties must be { type: string } per agentskills.io");
  }
  if (schema.additionalProperties !== false) {
    fail("additionalProperties must be false (portable fields only)");
  }
  if (!process.exitCode) {
    ok("Constraint checks (lengths, metadata string map, no extra fields)");
  }
}

async function checkSchemaAgainstSkillsReference() {
  const ref = await loadSkillsReference();
  const unexpected = ref.validateMetadata({
    name: "probe",
    description: "probe description for schema sync",
    "not-a-real-field": "x",
  });
  const mentionsUnexpected = unexpected.some((e) => /Unexpected fields/i.test(e));
  if (!mentionsUnexpected) {
    fail(
      "skills-reference did not reject an unknown frontmatter field; package may have diverged from agentskills.io",
    );
  } else {
    ok("skills-reference still rejects unknown frontmatter fields");
  }

  const allowedProbe = ref.validateMetadata({
    name: "probe",
    description: "probe description for schema sync",
    license: "MIT",
    compatibility: "test",
    metadata: { origin: "test" },
    "allowed-tools": "Read",
  });
  if (allowedProbe.length > 0) {
    fail(`skills-reference rejected portable fields: ${allowedProbe.join("; ")}`);
  } else {
    ok("skills-reference accepts the full portable field set");
  }
  return ref;
}

function listSkillDirs() {
  if (!existsSync(SKILLS_DIR)) return [];
  return readdirSync(SKILLS_DIR)
    .map((name) => join(SKILLS_DIR, name))
    .filter((p) => statSync(p).isDirectory() && existsSync(join(p, "SKILL.md")))
    .sort();
}

/** Extra checks that mirror schemas/skill.schema.json beyond skills-reference. */
function validateAgainstLocalSchema(skillDir, ref) {
  const errors = [];
  const skillMd = ref.findSkillMd(skillDir);
  if (!skillMd) return ["Missing SKILL.md"];

  let metadata;
  try {
    ({ metadata } = ref.parseFrontmatter(readFileSync(skillMd, "utf8")));
  } catch (err) {
    return [err instanceof Error ? err.message : String(err)];
  }

  for (const key of Object.keys(metadata)) {
    if (!SPEC_FIELDS.includes(key)) {
      errors.push(`Local schema: unexpected field '${key}'`);
    }
  }

  if (metadata.metadata != null) {
    if (typeof metadata.metadata !== "object" || Array.isArray(metadata.metadata)) {
      errors.push("Local schema: metadata must be a string→string map");
    } else {
      for (const [k, v] of Object.entries(metadata.metadata)) {
        if (typeof v !== "string") {
          errors.push(`Local schema: metadata.${k} must be a string (got ${typeof v})`);
        }
      }
    }
  }

  if (metadata["allowed-tools"] != null && typeof metadata["allowed-tools"] !== "string") {
    errors.push("Local schema: allowed-tools must be a string");
  }

  return errors;
}

function validateSkill(skillDir, ref) {
  const abs = resolve(skillDir);
  const name = basename(abs);
  console.log(`\n[skill] ${name}`);

  const refErrors = ref.validate(abs);
  for (const e of refErrors) fail(`skills-reference: ${e}`);
  if (refErrors.length === 0) ok("skills-reference");

  const localErrors = validateAgainstLocalSchema(abs, ref);
  for (const e of localErrors) fail(e);
  if (localErrors.length === 0) ok("local skill.schema.json");
}

async function main() {
  const args = process.argv.slice(2);
  const schemaOnly = args.includes("--schema");
  const paths = args.filter((a) => a !== "--schema");

  checkSchemaSyncBasics();
  if (process.exitCode) {
    console.error("\nValidation failed.");
    return;
  }

  const ref = await checkSchemaAgainstSkillsReference();
  if (process.exitCode) {
    console.error("\nValidation failed.");
    return;
  }

  if (schemaOnly) {
    console.log("\nAll schema checks passed.");
    return;
  }

  const targets = paths.length > 0 ? paths.map((p) => resolve(p)) : listSkillDirs();
  if (targets.length === 0) {
    fail("No skills found to validate");
    return;
  }

  for (const t of targets) {
    if (!existsSync(t) || !statSync(t).isDirectory()) {
      fail(`Not a skill directory: ${t}`);
      continue;
    }
    validateSkill(t, ref);
  }

  if (!process.exitCode) {
    console.log("\nAll checks passed.");
  } else {
    console.error("\nValidation failed.");
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
