// Injects CJK language options into the Carrot2 Workbench UI.
// This script is intended to be processed during a Docker build. The placeholder
// __CARROT2_LANG_EXTENSIONS__ will be replaced with a comma-separated list
// of enabled languages (e.g., "chinese,japanese,korean").
(function() {
  'use strict';

  const run = () => {
    // Placeholder will be replaced by Docker's sed command during build.
    const enabledExtensions = "__CARROT2_LANG_EXTENSIONS__";

    const langMap = {
      "chinese": ["Chinese-Simplified", "Chinese-Traditional"],
      "japanese": ["Japanese"],
      "korean": ["Korean"]
    };

    const languagesToAdd = enabledExtensions.split(',')
      .map(ext => ext.trim())
      .filter(ext => langMap[ext])
      .flatMap(ext => langMap[ext]);

    if (languagesToAdd.length === 0) {
      return;
    }

    const algorithms = ["kmeans", "lingo", "stc"];
    const processedSelects = new Set();

    // Function to append a new option to a select element.
    function appendOption(select, text, value) {
      if (Array.from(select.options).some(opt => opt.value === value)) {
        return; // Avoid adding duplicate options
      }
      const newOption = new Option(text, value);
      select.add(newOption);
    }

    // Function to sort options in a select element alphabetically.
    function sortOptions(select) {
      const selectedValue = select.value;
      const options = Array.from(select.options);

      options.sort((a, b) => a.text.localeCompare(b.text, undefined, {
        sensitivity: 'base'
      }));

      select.innerHTML = '';
      options.forEach(opt => select.add(opt));
      select.value = selectedValue; // Restore selection
    }

    // Function to add languages to a specific select element.
    function addLanguagesToSelect(select) {
      if (!select || processedSelects.has(select)) {
        return;
      }

      languagesToAdd.forEach(lang => {
        appendOption(select, lang, lang);
      });

      sortOptions(select);
      processedSelects.add(select);
    }

    // Also, try to find the elements on initial load, in case they're already there.
    algorithms.forEach(algorithm => {
      const selectId = `${algorithm}:language`;
      const section = document.getElementById(selectId);
      if (section) {
        const select = section.querySelector('select');
        addLanguagesToSelect(select);
      }
    });
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', run);
  } else {
    // The DOM is already ready.
    run();
  }
})();
