/**
 * Copyright (c) 2018 Helium Edu
 *
 * FIXME: This implementation is pretty crude compared to modern standards and will be completely overhauled in favor of a framework once the open source migration is completed.
 *
 * @license MIT
 * @version 1.5.1
 */

localStorage.removeItem("authtoken");

window.location.replace("/login");
