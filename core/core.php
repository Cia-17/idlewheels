
<?php

require_once __DIR__ . '/db_class.php';

// Start session if one has not already started
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// Redirect user to another page
function redirect_to($location)
{
    header("Location: " . $location);
    exit;
}

// Check whether a user is logged in
function is_logged_in()
{
    return isset($_SESSION['user_id']);
}

// Require the user to be logged in
function require_login()
{
    if (!is_logged_in()) {
        redirect_to('/Idlewheels/views/login.php');
    }
}

// Check the user's role
function require_role(...$allowedRoles)
{
    if (!is_logged_in()) {
        redirect_to('/Idlewheels/views/login.php');
    }

    $userRole = $_SESSION['role'] ?? '';

    if (!in_array($userRole, $allowedRoles, true)) {
        http_response_code(403);
        exit('Access denied. You do not have permission to access this page.');
    }
}

// Record application errors
function log_error($message)
{
    $errorDirectory = __DIR__ . '/../error';

    if (!is_dir($errorDirectory)) {
        mkdir($errorDirectory, 0755, true);
    }

    $logMessage = date('Y-m-d H:i:s') .
                  " - " . $message . PHP_EOL;

    error_log(
        $logMessage,
        3,
        $errorDirectory . '/error.log'
    );
}

?>
