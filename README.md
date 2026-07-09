# data-quality-checks — Data Quality Checks (PostgreSQL)

[![SQL Data Quality](https://github.com/r0meo-1/data-quality-checks/actions/workflows/sql-checks.yml/badge.svg)](https://github.com/r0meo-1/data-quality-checks/actions/workflows/sql-checks.yml)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-Data%20QA-336791)
![License](https://img.shields.io/badge/license-MIT-blue)

> Набор **SQL-проверок целостности и качества данных** для CRM туристического агентства
> (клиенты, туры, заявки, платежи). Каждая проверка — отдельный запрос, который ловит
> аномалии, дубли и рассинхронизацию. Прогон автоматизирован в **GitHub Actions** против
> реального **PostgreSQL**.
>
> Часть QA-портфолио: **[r0meo1.ru](https://r0meo1.ru)** · автор — Роман Неклюдов (Middle QA Engineer).

## Идея

В реальной работе data-quality проверки заменяют отсутствующие/ненадёжные ограничения
в выгрузках и интеграциях. Каждый чек возвращает **строки-нарушения**; норма — **0 строк**.
CI поднимает чистый PostgreSQL, загружает схему и эталонные данные, и прогоняет все проверки.

## Проверки

| Файл | Что проверяет |
|------|---------------|
| `check_01_duplicate_customer_emails.sql` | дубли клиентов по email |
| `check_02_orphan_bookings.sql` | заявки без клиента или тура |
| `check_03_orphan_payments.sql` | платежи без заявки |
| `check_04_paid_without_succeeded_payment.sql` | `paid`-заявки без успешного платежа |
| `check_05_payment_amount_mismatch.sql` | расхождение суммы заявки и оплат |
| `check_06_non_positive_amounts.sql` | нулевые/отрицательные суммы |
| `check_07_pax_sanity.sql` | число туристов: ≤0 или больше мест |
| `check_08_invalid_status.sql` | статусы вне словаря |
| `check_09_refunded_without_refund_payment.sql` | возврат без платежа `refunded` |
| `check_10_future_timestamps.sql` | даты в будущем |

## Структура

```
db/schema.sql           — схема (customers, tours, bookings, payments)
db/seed.sql             — эталонные данные (CI: все проверки зелёные)
db/seed-anomalies.sql   — «грязные» данные для демонстрации находок
checks/check_*.sql      — SQL-проверки (SELECT строк-нарушений)
scripts/run_checks.sh   — раннер: гоняет все чеки, падает при нарушениях
docs/findings-example.md — пример отчёта по аномалиям
```

## Запуск локально

```bash
# поднять локальный PostgreSQL (пример через docker)
docker run --rm -d --name dq -e POSTGRES_USER=qa -e POSTGRES_PASSWORD=qa \
  -e POSTGRES_DB=agency -p 5432:5432 postgres:16

export DATABASE_URL="postgresql://qa:qa@localhost:5432/agency"
export PGPASSWORD=qa

psql "$DATABASE_URL" -f db/schema.sql
psql "$DATABASE_URL" -f db/seed.sql
bash scripts/run_checks.sh        # → все проверки пройдены

# демонстрация находок на «грязных» данных:
psql "$DATABASE_URL" -f db/schema.sql
psql "$DATABASE_URL" -f db/seed-anomalies.sql
bash scripts/run_checks.sh        # → список нарушений (см. docs/findings-example.md)
```

## Стек

`SQL` · `PostgreSQL` · `Data QA` · `Bash` · `GitHub Actions` · `CI/CD`

## Контакты

- Сайт / портфолио: **[r0meo1.ru](https://r0meo1.ru)**
- Telegram: [@r0meo1](https://t.me/r0meo1) · Email: r0meo1@ya.ru · GitHub: [r0meo-1](https://github.com/r0meo-1)

## Лицензия

[MIT](LICENSE)
