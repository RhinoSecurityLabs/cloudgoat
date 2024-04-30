<!DOCTYPE HTML>
<html>
    <head>
        <title>SSRF</title>
    </head>

    <body>
        <h2>Server Side Request Forgery</h2>

        <form method="GET" action="">
            <span>URL:
                <input name="url" type="text" placeholder="" />
                <input type="submit" />
            </span>
        </form>
        <h4>Can you access meta-data? We've made security improvements!</h4>

<?php
if (isset($_GET['url'])) {
    $url = $_GET['url'];

    if (strlen($url) > 150) {
        echo "URL is too long. Please enter a URL with 150 characters or less.";
        echo "\n\n";
    } elseif (preg_match('/169.254.169.254/', $url)) {
        echo "Access to meta-data is not allowed.";
        echo "\n\n";
    } else {
        $response = shell_exec("curl --max-time 10 " . $url);
        if ($response === null) {
            error_log("Failed to execute curl for URL: " . escapeshellarg($url));
            echo "Failed to fetch the URL.";
            echo "\n\n";
        }
        else if ($response !== null) {
            echo "<pre>";
            echo htmlspecialchars($response);
            echo "</pre>";
        } else {
            echo "Failed to fetch the URL.";
            echo "\n\n";
        }
    }
}
?>

    </body>
</html>