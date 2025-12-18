<?php

declare(strict_types=1);

namespace App\Example;

use BaseInterface1,Other\Pkg\BaseInterface;

interface MyInterface extends BaseInterface1, BaseInterface
{
    // Interface methods
}