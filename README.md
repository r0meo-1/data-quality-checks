# data-quality-checks — SQL, который ловит враньё в данных

[![SQL Data Quality](https://github.com/r0meo-1/data-quality-checks/actions/workflows/sql-checks.yml/badge.svg)](https://github.com/r0meo-1/data-quality-checks/actions/workflows/sql-checks.yml)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-Data%20QA-336791)
![License](https://img.shields.io/badge/license-MIT-blue)

> CRM туристического агентства *уверена*, что всё в порядке.  
> Эти SQL-запросы — вежливый (но беспощадный) способ сказать: **«а ну-ка, покажи паспорт»**.

Набор **проверок целостности и качества данных** для CRM: клиенты, туры, заявки, платежи.  
Каждый чек — `SELECT` строк-нарушений. Норма — **0 строк**. Не ноль? Поздравляем, вы только что нашли баг… или бухгалтера. Иногда это одно и то же.

Часть портфолио: **[r0meo1.ru](https://r0meo1.ru)** · Роман Неклюдов

## За 20 секунд

| | |
|--|--|
| **Что** | SQL-проверки CRM-данных (дубли, сироты, суммы, статусы) |
| **Зачем** | Найти враньё в данных до того, как его увидит отчёт для бизнеса |
| **Проверить** | [CI](https://github.com/r0meo-1/data-quality-checks/actions) · `checks/check_*.sql` |

---

## Идея (коротко, без MBA)

Ограничения в БД — как ремни безопасности: полезны, пока их не отстегнули «временно на проде».  
Data quality checks живут **поверх** реальности интеграций и ручных правок:

1. CI поднимает чистый **PostgreSQL**
2. Заливает схему + эталон
3. Гоняет все `check_*.sql`
4. Падает, если кто-то решил, что «paid без платежа — это нормально»
5. Пересоздаёт схему только в изолированной CI-БД и загружает `seed-anomalies.sql`
6. Проверяет точное число нарушений каждого правила и ненулевой код раннера

На чистом наборе ожидается 0 строк для всех десяти правил. На аномальном —
по одной строке, кроме расхождения сумм: там две заявки (недоплата и отсутствие
успешного платежа). Так CI обнаруживает и ложные срабатывания, и проверки,
которые перестали находить дефекты. Сломанный SQL также завершает проверку ошибкой.

---

## Что ловим

| Файл | Преступление |
|------|----------------|
| `check_01_duplicate_customer_emails.sql` | Два клиента — один email (классика) |
| `check_02_orphan_bookings.sql` | Заявки-сироты без клиента/тура |
| `check_03_orphan_payments.sql` | Платежи в никуда |
| `check_04_paid_without_succeeded_payment.sql` | «Оплачено» на честном слове |
| `check_05_payment_amount_mismatch.sql` | Математика vs желания |
| `check_06_non_positive_amounts.sql` | Отрицательные деньги (смешно, пока не в проде) |
| `check_07_pax_sanity.sql` | Туристов ≤0 или «впихнули 40 в 2-местный» |
| `check_08_invalid_status.sql` | Статус `maybe_paid_lol` |
| `check_09_refunded_without_refund_payment.sql` | Возврат без возврата |
| `check_10_future_timestamps.sql` | Заявки из будущего (утечка из Delorean) |

---

## Структура

```
db/schema.sql            — схема
db/seed.sql              — чистые данные (CI зелёный)
db/seed-anomalies.sql    — «как сломать CRM за 5 минут»
checks/check_*.sql       — сами детективы
scripts/run_checks.sh    — раннер: нашёл нарушение → exit ≠ 0
scripts/verify_fixture.py — точные ожидаемые количества для обоих тестовых наборов
docs/findings-example.md — пример отчёта «ой»
```

---

## Запуск локально

```bash
docker run --rm -d --name dq -e POSTGRES_USER=qa -e POSTGRES_PASSWORD=qa \
  -e POSTGRES_DB=agency -p 5432:5432 postgres:16

export DATABASE_URL="postgresql://qa:qa@localhost:5432/agency"
export PGPASSWORD=qa

psql "$DATABASE_URL" -f db/schema.sql
psql "$DATABASE_URL" -f db/seed.sql
bash scripts/run_checks.sh        # → всё ок, можно выдохнуть
python3 scripts/verify_fixture.py clean

# режим «покажи ужасы»:
psql "$DATABASE_URL" -f db/schema.sql
psql "$DATABASE_URL" -f db/seed-anomalies.sql
bash scripts/run_checks.sh        # → список нарушений
python3 scripts/verify_fixture.py anomalies  # → подтверждение ожидаемых нарушений
```

---

## Стек

`SQL` · `PostgreSQL` · `Data QA` · `Bash` · `GitHub Actions`

## Связанные репы

- [api-automation-tests](https://github.com/r0meo-1/api-automation-tests) — API, когда данные ещё *делают вид*, что REST
- [test-design-docs](https://github.com/r0meo-1/test-design-docs) — бумага, без которой SQL кажется магией

## Контакты

- **[r0meo1.ru](https://r0meo1.ru)** · [@r0meo1](https://t.me/r0meo1) · r0meo1@ya.ru

## Лицензия

[MIT](LICENSE) — воруйте проверки, не воруйте деньги клиентов.
