"""Browser smoke test for the Flutter web build.

This script opens the app in Chrome, logs in with real credentials if provided,
walks through the main resident/admin flows, and prints browser console errors.

Usage:
  ADMIN_EMAIL=... ADMIN_PASSWORD=... COMMUNITY_SLUG=sca \
  API_BASE_URL=https://securecommapp-backend.onrender.com \
  WEB_BASE_URL=http://127.0.0.1:8000 python tooling/selenium_smoke_test.py

Expected local setup:
  1) Build the web app:
     flutter build web --release --dart-define=SCA_API_URL=...
  2) Serve build/web:
     cd build/web && python3 -m http.server 8000
"""

from __future__ import annotations

import os
import sys
import time
from dataclasses import dataclass
from typing import Iterable

from selenium import webdriver
from selenium.common.exceptions import TimeoutException, WebDriverException
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait


@dataclass(frozen=True)
class SmokeConfig:
    web_base_url: str
    api_base_url: str
    community_slug: str
    admin_email: str | None
    admin_password: str | None
    headless: bool = True


def _env(name: str, default: str | None = None) -> str | None:
    value = os.getenv(name, default)
    return value if value else None


def load_config() -> SmokeConfig:
    return SmokeConfig(
        web_base_url=_env("WEB_BASE_URL", "http://127.0.0.1:8000") or "http://127.0.0.1:8000",
        api_base_url=_env("API_BASE_URL", "https://securecommapp-backend.onrender.com")
        or "https://securecommapp-backend.onrender.com",
        community_slug=_env("COMMUNITY_SLUG", "sca") or "sca",
        admin_email=_env("ADMIN_EMAIL"),
        admin_password=_env("ADMIN_PASSWORD"),
        headless=(_env("HEADLESS", "1") or "1") not in {"0", "false", "False"},
    )


def build_driver(cfg: SmokeConfig) -> webdriver.Chrome:
    options = Options()
    if cfg.headless:
        options.add_argument("--headless=new")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--window-size=1440,1200")
    options.add_argument("--disable-gpu")
    options.add_argument("--enable-logging")
    options.add_argument("--v=1")
    options.set_capability("goog:loggingPrefs", {"browser": "ALL"})
    options.set_capability("pageLoadStrategy", "normal")
    return webdriver.Chrome(options=options)


def dump_console_logs(driver: webdriver.Chrome) -> list[str]:
    messages: list[str] = []
    for entry in driver.get_log("browser"):
        level = entry.get("level", "INFO")
        message = entry.get("message", "")
        line = f"[{level}] {message}"
        messages.append(line)
    return messages


def click_if_present(driver: webdriver.Chrome, xpath: str, timeout: float = 3.0) -> bool:
    try:
        element = WebDriverWait(driver, timeout).until(
            EC.element_to_be_clickable((By.XPATH, xpath))
        )
        element.click()
        return True
    except TimeoutException:
        return False


def type_into_first_visible(driver: webdriver.Chrome, selectors: Iterable[str], value: str) -> bool:
    for selector in selectors:
        try:
            element = driver.find_element(By.CSS_SELECTOR, selector)
            if element.is_displayed():
                element.clear()
                element.send_keys(value)
                return True
        except WebDriverException:
            continue
    return False


def login_as_admin(driver: webdriver.Chrome, cfg: SmokeConfig) -> None:
    if not cfg.admin_email or not cfg.admin_password:
        raise RuntimeError(
            "ADMIN_EMAIL y ADMIN_PASSWORD son obligatorios para probar el login del admin."
        )

    driver.get(cfg.web_base_url)
    wait = WebDriverWait(driver, 25)
    wait.until(EC.presence_of_element_located((By.TAG_NAME, "body")))

    if not type_into_first_visible(driver, ["input[type='text']", "input[autocomplete='username']"], cfg.admin_email):
        raise RuntimeError("No pude encontrar el campo de usuario/email en el login.")
    if not type_into_first_visible(driver, ["input[type='password']"], cfg.admin_password):
        raise RuntimeError("No pude encontrar el campo de contraseña en el login.")

    # Optional community selector if the page exposes it.
    type_into_first_visible(driver, ["input[name='community_slug']", "input[placeholder*='comunidad']"], cfg.community_slug)

    if not click_if_present(driver, "//button[contains(., 'Iniciar Sesión') or contains(., 'Iniciar sesión')]"):
        body = driver.find_element(By.TAG_NAME, "body")
        body.send_keys(Keys.TAB)
        body.send_keys(Keys.ENTER)

    wait.until(
        EC.any_of(
            EC.presence_of_element_located((By.XPATH, "//*[contains(., 'Panel de Administración')]")),
            EC.presence_of_element_located((By.XPATH, "//*[contains(., 'Secure Community App')]")),
        )
        )


def _click_sidebar_item(driver: webdriver.Chrome, label: str) -> None:
    xpaths = [
        f"//div[contains(@class, 'ListTile')][.//*[contains(., '{label}')]]",
        f"//li[contains(., '{label}')]",
        f"//span[contains(., '{label}')]",
        f"//*[self::div or self::button][contains(., '{label}')]",
    ]
    for xpath in xpaths:
        if click_if_present(driver, xpath, timeout=2.5):
            return
    raise RuntimeError(f"No pude abrir el módulo '{label}'.")


def _expect_any_text(driver: webdriver.Chrome, texts: Iterable[str], timeout: float = 8.0) -> None:
    wait = WebDriverWait(driver, timeout)
    wait.until(
        EC.any_of(
            *[EC.presence_of_element_located((By.XPATH, f"//*[contains(., '{text}')]")) for text in texts]
        )
    )


def _capture_console_warnings(driver: webdriver.Chrome) -> list[str]:
    messages = []
    for entry in driver.get_log("browser"):
        level = entry.get("level", "INFO")
        message = entry.get("message", "")
        if "SEVERE" in level or "WARNING" in level or "ERROR" in level:
            messages.append(f"[{level}] {message}")
    return messages


def smoke_navigate_admin(driver: webdriver.Chrome) -> None:
    # Each section validates that the target screen renders and is not blank/crashed.
    checks: list[tuple[str, tuple[str, ...]]] = [
        ("Dashboard", ("Bienvenido, Administrador", "Resumen general del condominio")),
        ("Residentes", ("Gestión de Residentes", "Residentes")),
        ("Accesos", ("Control de Accesos", "Control de Accesos y Visitas")),
        ("Avisos", ("Comunicados", "Nuevo Comunicado", "Avisos")),
        ("Reportes", ("Reportes", "Control de Reportes")),
        ("Mi perfil", ("Perfil", "Mi perfil")),
        ("Contraseñas", ("Cambios de contraseña", "Contraseñas")),
        ("Reglamento", ("Reglamento de convivencia", "Reglamento")),
        ("Preguntas FAQ", ("Preguntas frecuentes", "FAQ")),
        ("Notificaciones", ("Notificaciones",)),
    ]
    for label, expected_texts in checks:
        _click_sidebar_item(driver, label)
        _expect_any_text(driver, expected_texts)
        time.sleep(0.4)

    # Return to dashboard and open chat, which is the highest-risk module.
    _click_sidebar_item(driver, "Dashboard")
    _expect_any_text(driver, ("Bienvenido, Administrador",))
    click_if_present(driver, "//*[contains(., 'Chat Grupal Comunitario')]")
    _expect_any_text(driver, ("Chat Comunitario", "Chat Grupal Comunitario"))


def main() -> int:
    cfg = load_config()
    driver = build_driver(cfg)
    errors: list[str] = []
    try:
        login_as_admin(driver, cfg)
        smoke_navigate_admin(driver)
        time.sleep(1.5)
        errors = dump_console_logs(driver)
        errors.extend(_capture_console_warnings(driver))
    except Exception as exc:
        errors.extend(dump_console_logs(driver))
        errors.extend(_capture_console_warnings(driver))
        print(f"SMOKE FAILED: {exc}", file=sys.stderr)
        for line in errors:
            print(line, file=sys.stderr)
        return 1
    finally:
        driver.quit()

    print("SMOKE OK")
    if errors:
        print("Browser console:")
        for line in errors:
            print(line)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
