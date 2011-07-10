<?php

/*
 * ./htdocs/admin/index.php
 *
 * Copyright (C) 2011  Chris Howie <me@chrishowie.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

require_once(dirname(__FILE__) . '/common.inc.php');
$BTC_PROXY['average_interval'] = 900;
$pdo = db_connect();

$res = db_query($pdo,'select count(id)::float * 4294967296 / '.
                    (int)$BTC_PROXY['average_interval'].
                    ' / 1000000 as mhash from submitted_work where result=true and time > now() - \''.
                    (int)$BTC_PROXY['average_interval'].'seconds\'::interval');
                    
//$row = $res->fetch();

header("Content-type: image/png");
 
$string = sprintf('Mining at %.2f MH/s!',$res[0]['mhash']);
 
$font  = 4;
$width  = imagefontwidth($font) * strlen($string);
$height = imagefontheight($font);
 
$image = imagecreatetruecolor (200,16);
$white = imagecolorallocate ($image,255,255,255);
$black = imagecolorallocate ($image,0,0,0);
imagefill($image,0,0,$black);
 
imagestring ($image,$font,0,0,$string,$white);
 
imagepng ($image);
imagedestroy($image);
?>
