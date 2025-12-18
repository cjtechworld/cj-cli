<?php

declare(strict_types=1);

namespace App;

use Some\Base;
use Other\Pkg\Ifc;

class SmokeClass extends Base implements Ifc, LocalIfc
{
}