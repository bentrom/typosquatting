#!/usr/bin/php
<?php

if($argc < 2) die("Please provide at least one domain name as an argument\n");


$db = new mysqli('localhost','tromblbn','xx','tromblbn');

if ($db->connect_errno) die('Could not connect to database');

/* Declaring a 2D array representing a QWERTY keyboard */
$Qwerty = array(
	str_split("qwertyuiop"),
	str_split("asdfghjkl"),
	str_split("zxcvbnm")
);

/* Make Row and Column arrays for getting indexes of characters */
$Row = array();
$Column = array();

foreach($Qwerty as $i => $row) {
	foreach($row as $j => $c) {
		$Row[$c] = $i;
		$Column[$c] = $j;
	}
}

/* get_left,right,top,bottom get the character in the respective direction
*  of the given character. If not passed a valid character, or if the
*  character in the specified direction is not a valid character, then
*  returns the empty string.
*/
function get_left ($c) {
	global $Qwerty,$Row,$Column;
	if (!isset($Row[$c])) return "";
	if (isset($Qwerty[$Row[$c]][$Column[$c]-1])) return $Qwerty[$Row[$c]][$Column[$c]-1];
	return "";
}

function get_right ($c) {
	global $Qwerty,$Row,$Column;
	if (!isset($Row[$c])) return "";
	if (isset($Qwerty[$Row[$c]][$Column[$c]+1])) return $Qwerty[$Row[$c]][$Column[$c]+1];
	else return "";
}

function get_top ($c) {
	global $Qwerty,$Row,$Column;
	if (!isset($Row[$c])) return "";
	if (isset($Qwerty[$Row[$c]-1][$Column[$c]])) return $Qwerty[$Row[$c]-1][$Column[$c]];
	else return "";
}

function get_bottom ($c) {
	global $Qwerty,$Row,$Column;
	if (!isset($Row[$c])) return "";
	if (isset($Qwerty[$Row[$c]+1][$Column[$c]])) return $Qwerty[$Row[$c]+1][$Column[$c]];
	else return "";
}

/* Generate array of guesses which are very close to the domain */
function guesses ($domain) {
	$Guesses = array();
	for ($i = 0; $i < strlen($domain); $i++) {
		$left = get_left($domain[$i]);
		$right = get_right($domain[$i]);
		$top = get_top($domain[$i]);
		$bottom = get_bottom($domain[$i]);
		$c = $domain[$i];

		/* remove character from domain  */
		array_push($Guesses,substr_replace($domain,"",$i,1));
		
		/* For whichever exist amond left, right, top, and bottom,
		*  do the following: replace character with it, place it to
		* the left of the character, and then to the right
		*/
		if ($left != "") {
			array_push($Guesses,
				substr_replace($domain,$left,$i,1),
				substr_replace($domain,$left.$c,$i,1),
				substr_replace($domain,$c.$left,$i,1));
		}
		if ($right != "") {
			array_push($Guesses,
				substr_replace($domain,$right,$i,1),
				substr_replace($domain,$right.$c,$i,1),
				substr_replace($domain,$c.$right,$i,1));
		}
		if ($top != "") {
			array_push($Guesses,
				substr_replace($domain,$top,$i,1),
				substr_replace($domain,$top.$c,$i,1),
				substr_replace($domain,$c.$top,$i,1));
		}
		if ($bottom != "") {
			array_push($Guesses,
				substr_replace($domain,$bottom,$i,1),
				substr_replace($domain,$bottom.$c,$i,1),
				substr_replace($domain,$c.$bottom,$i,1));
		}

		/* if the character is a letter, duplicate it  */
		if (preg_match('/[a-z]/',$c)) {
			array_push($Guesses,substr_replace($domain,$c.$c,$i,1));
		}

		/* Swap the character with the previous character */
		if ($i > 0) {
			$c2 = $domain[$i-1];
			array_push($Guesses,substr_replace($domain,$c.$c2, $i-1,2));
		}
		
		$index = strrpos($domain,".");
		if ($index !== FALSE) {
			array_push($Guesses,
				substr_replace($domain,'.com',$index),
				substr_replace($domain,'.org',$index),
				substr_replace($domain,'.gov',$index),
				substr_replace($domain,'.edu',$index),
				substr_replace($domain,'.net',$index));
		}
		
	}
	/* remove all duplicates and return */
	return array_unique($Guesses);
}

/* Prepare insert statements */
$insert = $db->prepare("INSERT INTO guesses VALUES (?,?,?)");
$update = $db->prepare("UPDATE guesses SET redirect = ? WHERE guess = ?");

$preg = "/\A[A-Za-z0-9_.-~]+\z/";

for ($i = 1; $i < $argc; ++$i) {

	$link = $argv[$i];

	if ( !preg_match($preg,$link) ) {
		echo "URL: $link contains inappropriate characters\n";
		continue;
	}

	echo "Generating gueeses for: $link\n";
	$Guesses = guesses($link);

	foreach ($Guesses as $guess) {

		$Matches = array();
		$Results = array();
		echo "$guess... ";
		/* Run script/888 to get all redirect data */
		$result = exec("./get_url.sh $guess $guess",$Results);
		
		/* Insert into Guesses table */
		$insert->bind_param("sss",$link,$guess,$result);
		if ($insert->execute()) echo "success\n";
		else {
			$update->bind_param("ss",$result,$guess);
			if ($update->execute()) echo "updated\n";
			else echo "Execute failed\n";
		}
	}
}

/* Remove the files generated from wget that are empty */
exec("./delete_empty.sh");

mysqli_close($db);

?>

