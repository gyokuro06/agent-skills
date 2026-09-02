# Gauge TDD — Reference

## Thin Step delegating to Page Object

```kotlin
class HeaderStep {
    private val header get() = AppHeader(page)

    @Step("ヘッダーに「取り込み」リンクが表示されている")
    fun ヘッダーに取り込みリンクが表示されている() {
        header.assertImportLinkVisible()
    }
}
```

## Component Page Object

```kotlin
class AppHeader(private val page: Page) {
    private val root = page.getByRole(AriaRole.BANNER)
    private val navigation = root.getByRole(AriaRole.NAVIGATION)

    fun assertImportLinkVisible() {
        PlaywrightAssertions.assertThat(importLink()).isVisible()
    }

    fun clickImportLink() {
        importLink().click()
    }

    private fun importLink(): Locator =
        navigation.getByRole(AriaRole.LINK, Locator.GetByRoleOptions().setName("取り込み"))
}
```

## Screen Page Object

```kotlin
class ImportPage(page: Page) : BasePage(page) {
    fun assertUrl() {
        PlaywrightAssertions.assertThat(playwrightPage).hasURL(Pattern.compile(".*/import$"))
    }

    fun assertVisible() {
        PlaywrightAssertions.assertThat(heading()).isVisible()
    }

    private fun heading(): Locator =
        playwrightPage
            .getByRole(AriaRole.MAIN)
            .getByRole(AriaRole.HEADING, Locator.GetByRoleOptions().setName("取り込み"))
}
```

## Contextual step spec

```gauge
# ヘッダー

* "/"を開く

## ヘッダーに取り込みへの動線がある
* ヘッダーに「取り込み」リンクが表示されている
```

## Parameterized navigation step

```kotlin
@Step("<path>を開く")
fun パスを開く(path: String) {
    BasePage.open(path)
}
```

Spec: `* "/import"を開く`

## Red vs not-Red

| Observation | Counts as Red? |
|-------------|----------------|
| Gauge scenario fails on assertion | Yes |
| Step implementation not found | No—fix binding first |
| Kotlin compile error | No—fix compile first |
| Scenario passes unexpectedly | Wrong—scenario or app already satisfies AC |
