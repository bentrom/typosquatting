typosquatting
=============

Perl tool for collecting data about websites and typos of the websites. This version uses MySQL.

TO USE:

1. To use the Perl script, edit typo_squat.pl line 8 to include your username, password, and database for MySQL.
2. If using MySQL, run the following command (with your database name): mysql DATABASE < create_statements.sql
3. If not using MySQL, you can use the create statements contained in create_statements.sql for the necessary tables
4. Call typo_squat.pl DOMAIN.NAMES with whatever domain you please to fill the database with information based on that domain name (NOTE: you can include multiple domain names here).
