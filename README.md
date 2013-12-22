Various utilities, in a Ruby class and several PostgreSQL functions, to handle SAT grid-in responses, including assessing correctness using the same criteria that the College Board does.

A valid grid-in response is four characters and includes only whitespace, a decimal point, and/or a slash denoting a fraction. For example:

    "  45"
    "45  "
    ".345"
    "9.78"
    "1/14"

A valid grid-in key can include specific values, ranges, or a list thereof. For example:

    "45"
    "5.6"
    "3/7" # By the College Board's rules, "3/7", ".428" and ".429" are all acceptable.
    "[45,50)" # PostgreSQL-esque range notation; equivalent to 45 ≤ x < 50.
    "2;.5;6/7;(9.5,10.5]" # List notation; anything satisfying 2, .5, 6/7, or 9.5 < x ≤ 10.5 is correct.

Specs require the Sequel gem and Postgres. Pass in a server url as DATABASE_URL.
