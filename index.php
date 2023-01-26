<!DOCTYPE html>
<?php
$page = $_SERVER['PHP_SELF'];
$sec = "5";
?>
<html>
    <head>
    <meta http-equiv="refresh" content="<?php echo $sec?>;URL='<?php echo $page?>'">
    </head>
    <body>
    <?php
        echo "The page automatic reload itself every 5 seconds!";
    ?>
    </body>
</html>

<html>
  <body>
    <p><?php echo "hostname is: ".gethostname(); ?></p>
    <p><?php echo "current dir is: ".getcwd(); ?></p>
    <p><?php echo date("D M j G:i:s T Y"); ?></p>
  </body>
</html>
