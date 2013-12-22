-- Functions that handle grid-in responses on the SAT.

-- Convert a singular (non-concatenative) grid-in field to a numeric.
CREATE FUNCTION pg_temp.parse_gridin(response text)
RETURNS NUMERIC
LANGUAGE PLPGSQL
AS $$
  BEGIN
    RETURN CASE
      WHEN response ~ '/' THEN
        CAST(substring(response from '^(.*)/') AS NUMERIC) / CAST(substring(response from '/(.*)$') AS NUMERIC)
      ELSE
        CAST(response AS NUMERIC)
    END;
  -- Have to handle wonky input that can't become a numeric.
  EXCEPTION WHEN invalid_text_representation OR division_by_zero THEN
    RETURN NULL;
  END;
$$;

-- Need to be able to figure out how many decimal places are necessary for an
-- answer.
CREATE FUNCTION pg_temp.gridin_decimal_places(value numeric)
RETURNS INTEGER
LANGUAGE SQL
AS $$
  SELECT CASE
    WHEN value >= 0.0  AND value < 1.0   THEN 3
    WHEN value >= 1.0  AND value < 10.0  THEN 2
    WHEN value >= 10.0 AND value < 100.0 THEN 1
    ELSE 3
  END
$$;

-- The SAT rules say that for an answer like 2/3, either .666 or .667 is
-- acceptable. So, we have a concept of "close enough".
CREATE FUNCTION pg_temp.gridin_close_enough(answer numeric, response numeric)
RETURNS BOOLEAN
LANGUAGE SQL
AS $$
  SELECT
    CASE
      -- When the user's response has the correct number of decimal places...
      WHEN round(response, pg_temp.gridin_decimal_places(response)) = response THEN
        -- ...we accept either a rounded answer (.667) or a truncated one (.666).
        round(answer, pg_temp.gridin_decimal_places(response)) = response OR
        trunc(answer, pg_temp.gridin_decimal_places(response)) = response
      ELSE
        -- But most of the time, straight equivalence will do.
        answer = response
    END;
$$;

-- When the answer is a range, we accept any value within it, but also "close-
-- enough" matches to the endpoints.
CREATE FUNCTION pg_temp.gridin_range_equivalent(l numeric, r numeric, include_l boolean, include_r boolean, response numeric)
RETURNS BOOLEAN
LANGUAGE SQL
AS $$
  SELECT CASE
    WHEN include_l AND pg_temp.gridin_close_enough(l, response) THEN true
    WHEN include_r AND pg_temp.gridin_close_enough(r, response) THEN true
    ELSE response > l AND response < r
  END
$$;

-- This is the function commonly used by other code. The answer can either be a
-- single value or a range.
CREATE FUNCTION pg_temp.gridin_equivalent(answer text, response text)
RETURNS BOOLEAN
LANGUAGE SQL
AS $$
  -- Use coalesce because input that can't cleanly become a numeric will be
  -- null, and null = null is null.
  SELECT coalesce(
    CASE
      WHEN answer ~ ';' THEN
        (SELECT bool_or(pg_temp.gridin_equivalent(i, response)) FROM unnest(string_to_array(answer, ';')) i)
      WHEN answer ~ ',' THEN
        pg_temp.gridin_range_equivalent(
          pg_temp.parse_gridin(substring(answer from '^[\[\(](.*),')),
          pg_temp.parse_gridin(substring(answer from ',(.*)[\]\)]$')),
          substring(answer from '^\[') IS NOT NULL,
          substring(answer from '\]$') IS NOT NULL,
          pg_temp.parse_gridin(response)
        )
      ELSE
        pg_temp.gridin_close_enough(pg_temp.parse_gridin(answer), pg_temp.parse_gridin(response))
    END, FALSE);
$$;

-- Check whether an answer was entered as a mixed number
CREATE FUNCTION pg_temp.gridin_mixed_answer(answer text, response text)
RETURNS BOOLEAN
LANGUAGE SQL
AS $$
  SELECT CASE
    WHEN response ~ '^\d\d/\d$' THEN
      pg_temp.gridin_equivalent(answer, (
        -- For 12/3, return (1 * 3 + 2) / 3
        (
          substring(response from '^(\d)\d/\d$')::integer *
          substring(response from '^\d\d/(\d)$')::integer +
          substring(response from '^\d(\d)/\d$')::integer
        )::text
          || '/'
          || substring(response from '^\d\d/(\d)$')
      )::text)
    ELSE FALSE
    END;
$$;
