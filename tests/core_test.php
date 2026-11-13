
<?php

require_once __DIR__ . '/../core/core.php';

echo "<h2>IdleWheels Core System Test</h2>";

// TEST 1: Session management
if (session_status() === PHP_SESSION_ACTIVE) {
    echo "TEST 1 PASSED: Session started successfully.<br>";
} else {
    echo "TEST 1 FAILED: Session did not start.<br>";
}

// TEST 2: Login check
unset($_SESSION['user_id']);

if (!is_logged_in()) {
    echo "TEST 2 PASSED: Logged-out user detected.<br>";
} else {
    echo "TEST 2 FAILED: Login check is incorrect.<br>";
}

// Simulate a logged-in user
$_SESSION['user_id'] = 1;
$_SESSION['role'] = 'test_role';

if (is_logged_in()) {
    echo "TEST 3 PASSED: Logged-in user detected.<br>";
} else {
    echo "TEST 3 FAILED: Login check is incorrect.<br>";
}

// TEST 4: Role access control
try {
    require_role('test_role');

    echo "TEST 4 PASSED: Correct user role accepted.<br>";

} catch (Throwable $e) {
    echo "TEST 4 FAILED: " .
         htmlspecialchars($e->getMessage()) . "<br>";
}

// TEST 5: Error logging
log_error("IdleWheels core system test");

$errorFile = __DIR__ . '/../error/error.log';

if (file_exists($errorFile)) {
    echo "TEST 5 PASSED: Error log file created successfully.<br>";
} else {
    echo "TEST 5 FAILED: Error log file was not created.<br>";
}

?>
