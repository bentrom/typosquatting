typosquatting-analyzer
======================

PHP and Perl tools for collecting data about websites and typos of the websites. This version uses MySQL.

TO USE:

1. To use the Perl script, edit typo_squat.pl line 3 to include your username and password for MySQL (or even change the database being used).
2. To use the PHP script, edit typo_squat.ph line 5 to include your username and password for MySQL.
3. If using MySQL, run the following command (with your database name): mysql DATABASE < create_statements.sql
4. If not using MySQL, you can use the create statements contained in create_statements.sql for the necessary tables
5. Call typo_squat.pl DOMAIN.NAME or typo_squat.ph DOMAIN.NAME with whatever domain you please to fill the database with information based on that domain name.
