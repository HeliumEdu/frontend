/// No-op stubs used on non-web platforms.
void triggerBrowserPrint() {}

bool getSystemReduceMotion() => false;

bool getSystemIncreaseContrast() => false;

void reloadPage() {}

void warnBeforeUnloadWhile(bool Function() hasUnsavedChanges) {}
