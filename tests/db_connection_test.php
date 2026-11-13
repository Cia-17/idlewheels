
<?php

require_once __DIR__ . '/../core/db_class.php';

try {

    $database = new Database();

    $conn = $database->getConnection();

    $stmt = $conn->query("SELECT DATABASE() AS database_name");

    $result = $stmt->fetch();

    if ($result['database_name'] === 'idlewheels') {

        echo "SUCCESS: Database connected successfully!";
        echo "<br>Connected database: " .
             htmlspecialchars($result['database_name']);

    } else {

        echo "ERROR: Connected to the wrong database.";

    }

} catch (Throwable $e) {

    echo "CONNECTION FAILED: " .
         htmlspecialchars($e->getMessage());

}

?>
