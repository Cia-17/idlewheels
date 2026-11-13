
<?php

require_once __DIR__ . '/db_cred.php';

class Database
{
    private $conn;

    public function __construct()
    {
        try {
            $dsn = "mysql:host=" . DB_HOST .
                   ";dbname=" . DB_NAME .
                   ";charset=" . DB_CHARSET;

            $options = [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false
            ];

            $this->conn = new PDO(
                $dsn,
                DB_USER,
                DB_PASS,
                $options
            );

        } catch (PDOException $e) {

            $errorMessage = date('Y-m-d H:i:s') .
                            " - Database connection failed: " .
                            $e->getMessage() . PHP_EOL;

            $errorDirectory = __DIR__ . '/../error';

            if (!is_dir($errorDirectory)) {
                mkdir($errorDirectory, 0755, true);
            }

            error_log(
                $errorMessage,
                3,
                $errorDirectory . '/error.log'
            );

            throw new RuntimeException(
                "Database connection failed. Check the error log."
            );
        }
    }

    public function getConnection(): PDO
    {
        return $this->conn;
    }
}

?>
