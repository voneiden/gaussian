export function setDocumentClass(className) {
  if (className === "dark") {
    document.documentElement.classList.add("dark");
    document.documentElement.classList.remove("light");
  } else {
    document.documentElement.classList.add("light");
    document.documentElement.classList.remove("dark");
  }
}

export function getPreferredColorScheme() {
  if (typeof window !== 'undefined' && window.matchMedia) {
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? "dark" : "light";
  }
  return "light";
}

export function saveSettings(decimalPrecision) {
  if (typeof localStorage !== 'undefined') {
    localStorage.setItem('gaussian_settings', JSON.stringify({
      decimal_precision: decimalPrecision
    }));
  }
}

export function loadSettings() {
  if (typeof localStorage !== 'undefined') {
    const saved = localStorage.getItem('gaussian_settings');
    if (saved) {
      try {
        const settings = JSON.parse(saved);
        return settings.decimal_precision || 3;
      } catch (e) {
        return 3;
      }
    }
  }
  return 3;
}
