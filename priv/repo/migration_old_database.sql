\c postgres

\set old_data_base 'doofinder_old'
\set new_data_base 'siwapp_dev'

DROP DATABASE IF EXISTS temp;
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = :old_data_base
AND pid <> pg_backend_pid();
CREATE DATABASE temp
  WITH TEMPLATE :old_data_base
    OWNER postgres;

\c temp
ALTER TABLE taxes RENAME TO taxes_ror;
ALTER TABLE series RENAME TO series_ror;
ALTER TABLE items RENAME TO items_ror;
ALTER TABLE items_ror DROP COLUMN product_id;
ALTER TABLE customers RENAME TO customers_ror;
ALTER TABLE payments RENAME TO payments_ror;
ALTER TABLE items_taxes RENAME TO items_taxes_ror;
CREATE TABLE commons_id_type_invoice(id integer);
INSERT INTO commons_id_type_invoice
  SELECT id FROM commons
    WHERE type='Invoice' ORDER BY id ASC;

CREATE FUNCTION change_column_with_function(table_name text, column_name text, t text, fun text)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  EXECUTE 'ALTER TABLE ' || table_name || ' ALTER COLUMN ' || column_name || ' TYPE ' || t || ' USING ' || fun || '(' || column_name || ')';
END; $$;

CREATE FUNCTION to_cents(amount numeric)
RETURNS integer
LANGUAGE plpgsql
AS $$
BEGIN
  return amount*100;
END; $$;

CREATE FUNCTION period_type_conversion(period_type character varying(8))
RETURNS character varying(8)
LANGUAGE plpgsql
AS $$
DECLARE result character varying(8);
BEGIN
  case period_type
    when 'month' then result = 'Monthly';
    when 'day' then result = 'Daily';
    when 'year' then result = 'Yearly';
    else result='';
  end case;
  return result;
END; $$;

CREATE FUNCTION currency_conversion(currency character varying(3))
RETURNS character varying(3)
LANGUAGE plpgsql
AS $$
DECLARE result character varying(3);
BEGIN
    if currency IS NULL then result = 'USD';
    else result=UPPER(currency);
    end if;
    return result;
END; $$;

CREATE FUNCTION remove_empty_strings(identification character varying(50))
RETURNS character varying(50)
LANGUAGE plpgsql
AS $$
DECLARE result character varying(50);
BEGIN
   SELECT NULLIF(identification, '') INTO result;
   return result;
END; $$;

CREATE FUNCTION change_metattributes(meta_attribute text)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE result jsonb;
BEGIN
    if meta_attribute IS NULL then result = '{}';
    else result = meta_attribute::jsonb;
    end if;
    return result;
END; $$;

SELECT change_column_with_function('commons', 'net_amount', 'integer', 'to_cents') AS net_amount_to_cents;
SELECT change_column_with_function('commons', 'gross_amount', 'integer', 'to_cents') AS gross_amount_to_cents;
SELECT change_column_with_function('commons', 'paid_amount', 'integer', 'to_cents') AS paid_amount_to_cents;
SELECT change_column_with_function('commons', 'currency', 'character varying(3)', 'currency_conversion') AS currency_conversion;
SELECT change_column_with_function('commons', 'identification', 'character varying(50)', 'remove_empty_strings') AS prune_empty_identification_commons;
SELECT change_column_with_function('items_ror', 'unitary_cost', 'integer', 'to_cents') AS unitary_cost_to_cents;
SELECT change_column_with_function('payments_ror', 'amount', 'integer', 'to_cents') AS amount_to_cents;
SELECT change_column_with_function('commons', 'period_type', 'character varying(8)', 'period_type_conversion') AS period_type_conversion;
SELECT change_column_with_function('customers_ror', 'identification', 'character varying(50)', 'remove_empty_strings') AS prune_empty_identification_customers;
SELECT change_column_with_function('customers_ror', 'meta_attributes', 'jsonb', 'change_metattributes') AS customer_meta_attributes;
SELECT change_column_with_function('commons', 'meta_attributes', 'jsonb', 'change_metattributes') AS commons_meta_attributes;

CREATE TABLE items_invoices AS (SELECT * FROM items_ror WHERE common_id IN (SELECT * FROM commons_id_type_invoice) AND deleted_at IS NULL);
CREATE TABLE items_recurring_invoices AS (SELECT * FROM items_ror WHERE id NOT IN (SELECT id FROM items_invoices) AND deleted_at IS NULL);
ALTER TABLE items_ror DROP COLUMN deleted_at;

DROP TABLE schema_migrations;
DROP TABLE settings;
DROP TABLE templates;
DROP TABLE users;
DROP TABLE webhook_logs;
DROP TABLE tags;
DROP TABLE taggings;
DROP TABLE products;
DROP TABLE commons_id_type_invoice;
DROP FUNCTION change_column_with_function;
DROP FUNCTION to_cents;
DROP FUNCTION period_type_conversion;

\c :new_data_base
CREATE EXTENSION postgres_fdw;
CREATE SERVER localsrv FOREIGN DATA WRAPPER postgres_fdw OPTIONS(host 'localhost', dbname 'temp', port '5432');
CREATE USER MAPPING FOR postgres SERVER localsrv OPTIONS(user 'postgres', password 'postgres');
IMPORT FOREIGN SCHEMA public FROM SERVER localsrv INTO public;

ALTER TABLE customers ALTER COLUMN hash_id TYPE character varying(100);
ALTER TABLE taxes ADD COLUMN old_id integer;
ALTER TABLE series ADD COLUMN old_id integer;
ALTER TABLE customers ADD COLUMN old_id integer;
ALTER TABLE recurring_invoices ADD COLUMN old_id integer;
ALTER TABLE invoices ADD COLUMN old_id integer;
ALTER TABLE items ADD COLUMN old_id integer;

--taxes
-- value in ror was numeric, ours will round decimals
INSERT INTO taxes(name, value, enabled, "default", old_id) SELECT name, value, active, "default", id FROM taxes_ror WHERE deleted_at IS NULL ORDER BY taxes_ror.id ASC;
SELECT 'taxes done' AS msg;

--series
INSERT INTO series(old_id, name, code, enabled, "default", first_number) SELECT id, name, value, enabled, "default", first_number FROM series_ror WHERE deleted_at IS NULL ORDER BY series_ror.id ASC;
SELECT 'series done'AS msg;

--customers
INSERT INTO customers(old_id, name, hash_id, identification, email, contact_person, invoicing_address, shipping_address, meta_attributes, inserted_at, updated_at)
  SELECT id, name, name_slug, identification, email, contact_person, invoicing_address, shipping_address, meta_attributes, NOW(), NOW() FROM customers_ror;
SELECT 'customers done' AS msg;

--recurring_invoices
CREATE FUNCTION build_items(id bigint)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE result jsonb;
BEGIN
    DROP TABLE IF EXISTS items_one_recurring_invoice;
    CREATE TABLE items_one_recurring_invoice(index serial, item jsonb);
    CREATE SEQUENCE index START 1 OWNED BY items_one_recurring_invoice.index;
    INSERT INTO items_one_recurring_invoice(item)
      SELECT row_to_json(t) FROM
      (SELECT taxes, discount, quantity, description, unitary_cost
        FROM items_ror_extended WHERE common_id=id) t;
    WITH data(index, item) AS (SELECT * FROM items_one_recurring_invoice)
      SELECT json_object_agg(index-1,item) INTO result FROM data;
    return result;
END; $$;

CREATE TABLE items_taxes_names(item_id integer, taxes text[]);
INSERT INTO items_taxes_names
  SELECT items_recurring_invoices.id, array_remove(array_agg(taxes.name), NULL) FROM items_recurring_invoices
    LEFT JOIN items_taxes_ror ON items_recurring_invoices.id=item_id
      LEFT JOIN taxes ON taxes.old_id=tax_id GROUP BY item_id, items_recurring_invoices.id ORDER BY items_recurring_invoices.id ASC;

CREATE TABLE items_ror_extended(common_id bigint, taxes text[], discount integer, quantity integer, description character varying(20000), unitary_cost integer);
INSERT INTO items_ror_extended
  SELECT common_id, taxes, discount, quantity, description, unitary_cost FROM items_recurring_invoices
    LEFT JOIN items_taxes_names ON items_taxes_names.item_id=items_recurring_invoices.id;

INSERT INTO recurring_invoices(series_id, customer_id, name, identification, email, invoicing_address, shipping_address, contact_person, terms, notes, net_amount, gross_amount, send_by_email, days_to_due, enabled, max_ocurrences, period, period_type, starting_date, finishing_date, inserted_at, updated_at, currency, items, meta_attributes, old_id)
  SELECT series.id, customers.id, commons.name, commons.identification, commons.email, commons.invoicing_address, commons.shipping_address, commons.contact_person, commons.terms, commons.notes, net_amount, gross_amount, sent_by_email, days_to_due, commons.enabled, max_occurrences, period, period_type, starting_date, finishing_date, created_at, commons.updated_at, currency, build_items(commons.id), commons.meta_attributes, commons.id
    FROM commons
      LEFT OUTER JOIN customers ON customers.old_id=commons.customer_id
        LEFT OUTER JOIN series ON series.old_id=commons.series_id
          WHERE type='RecurringInvoice' AND commons.deleted_at IS NULL ORDER BY commons.id ASC;

SELECT 'recurring_invoices done' AS msg;

--invoices
INSERT INTO invoices(series_id, customer_id, name, identification, email, invoicing_address, shipping_address, contact_person, terms, notes, net_amount, gross_amount, paid_amount, draft, paid, sent_by_email, "number", recurring_invoice_id, issue_date, due_date, inserted_at, updated_at, deleted_at, failed, currency, meta_attributes, old_id)
  SELECT series.id, customers.id, commons.name, commons.identification, commons.email, commons.invoicing_address, commons.shipping_address, commons.contact_person, commons.terms, commons.notes, commons.net_amount, commons.gross_amount, commons.paid_amount, commons.draft, commons.paid, commons.sent_by_email, commons."number", recurring_invoices.id, commons.issue_date, commons.due_date, commons.created_at, commons.updated_at, commons.deleted_at, commons.failed, commons.currency, commons.meta_attributes, commons.id
    FROM commons
      LEFT OUTER JOIN recurring_invoices ON recurring_invoices.old_id=commons.recurring_invoice_id
        LEFT OUTER JOIN customers ON customers.old_id=commons.customer_id
          LEFT OUTER JOIN series ON series.old_id=commons.series_id
            WHERE commons.type='Invoice' ORDER BY commons.id ASC;

SELECT 'invoices done' AS msg;

--items
-- discount and quantity in ror were numeric, ours will round decimals
INSERT INTO items(quantity, discount, description, unitary_cost, invoice_id, old_id)
  SELECT quantity, discount, description, unitary_cost, invoices.id, items_invoices.id FROM items_invoices
    LEFT JOIN invoices ON items_invoices.common_id=invoices.old_id
    ORDER BY items_invoices.id ASC;
SELECT 'items done' AS msg;

-- payments
INSERT INTO payments("date", amount, notes, invoice_id, inserted_at, updated_at)
  SELECT "date", amount, payments_ror.notes, invoices.id, created_at, payments_ror.updated_at FROM payments_ror
    LEFT JOIN invoices ON invoices.old_id=payments_ror.invoice_id
    ORDER BY payments_ror.id ASC;
SELECT 'payments done' AS msg;

-- items_taxes
INSERT INTO items_taxes
  SELECT items.id, taxes.id FROM items_taxes_ror
    RIGHT OUTER JOIN items ON items.old_id=items_taxes_ror.item_id
      RIGHT OUTER JOIN taxes ON taxes.old_id=items_taxes_ror.tax_id
        ORDER BY items.id ASC;
SELECT 'items_taxes done' AS msg;

DROP FOREIGN TABLE taxes_ror;
DROP FOREIGN TABLE series_ror;
DROP FOREIGN TABLE customers_ror;
DROP FOREIGN TABLE commons;
DROP FOREIGN TABLE items_taxes_ror;
DROP FOREIGN TABLE items_ror;
DROP FOREIGN TABLE payments_ror;
DROP FOREIGN TABLE items_invoices;
DROP FOREIGN TABLE items_recurring_invoices;
DROP TABLE items_one_recurring_invoice;
DROP TABLE items_taxes_names;
DROP TABLE items_ror_extended;
DROP FUNCTION build_items;
DROP EXTENSION postgres_fdw CASCADE;
DROP SERVER localsrv CASCADE;
ALTER TABLE taxes DROP COLUMN old_id;
ALTER TABLE series DROP COLUMN old_id;
ALTER TABLE customers DROP COLUMN old_id;
ALTER TABLE recurring_invoices DROP COLUMN old_id;
ALTER TABLE invoices DROP COLUMN old_id;
ALTER TABLE items DROP COLUMN old_id;

\c postgres
DROP DATABASE temp;
