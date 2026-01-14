// Injects CJK language options into the Carrot2 Workbench UI.
// This script is intended to be processed during a Docker build. The placeholder
// __CARROT2_LANG_EXTENSIONS__ will be replaced with a comma-separated list
// of enabled languages (e.g., "chinese,japanese,korean").
(function() {
  'use strict';

  /**
   * Appends a new option to a select element, avoiding duplicates.
   */
  function appendOption(select, text, value) {
    // Avoid adding duplicate options by checking existing values.
    if (Array.from(select.options).some(opt => opt.value === value)) {
      return;
    }
    const newOption = new Option(text, value);
    select.add(newOption);
  }

  /**
   * Sorts options in a select element alphabetically by text, preserving the selection.
   */
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

  const run = () => {
    // Central configuration for all selectors and options.
    const CONFIG = {
      // This placeholder is replaced by Docker's sed command during build.
      enabledExtensionsString: "__CARROT2_LANG_EXTENSIONS__",

      // Config for algorithm-specific language dropdowns (e.g., kmeans:language).
      algorithmLanguages: {
        selectors: ["kmeans:language", "lingo:language", "stc:language"],
        options: {
          "chinese": ["Chinese-Simplified", "Chinese-Traditional"],
          "japanese": ["Japanese"],
          "korean": ["Korean"]
        }
      },

      // Config for web-interface-specific dropdowns (e.g., web:language).
      web: {
        "web:language": {
          "chinese": [{ text: "Chinese", value: "zh" }],
          "japanese": [{ text: "Japanese", value: "ja" }],
          "korean": [{ text: "Korean", value: "ko" }]
        },
        "web:country": {
          "chinese": [
            { text: "China", value: "CN" },
            { text: "Hong Kong", value: "HK" },
            { text: "Taiwan", value: "TW" }
          ],
          "japanese": [{ text: "Japan", value: "JP" }],
          "korean": [{ text: "South Korea", value: "KR" }]
        }
      }
    };

    const enabled = CONFIG.enabledExtensionsString.split(',').map(s => s.trim()).filter(Boolean);

    // If no extensions are enabled or the placeholder wasn't replaced, do nothing.
    if (enabled.length === 0 || CONFIG.enabledExtensionsString.startsWith("__CARROT2")) {
      return;
    }

    const processedSelects = new Set();

    /**
     * Populates language options for algorithms like Lingo, STC, etc.
     */
    const populateAlgorithmLanguages = () => {
      const languagesToAdd = enabled
        .filter(ext => CONFIG.algorithmLanguages.options[ext])
        .flatMap(ext => CONFIG.algorithmLanguages.options[ext]);

      if (languagesToAdd.length === 0) {
        return;
      }

      CONFIG.algorithmLanguages.selectors.forEach(selectorId => {
        const section = document.getElementById(selectorId);
        if (section) {
          const select = section.querySelector('select');
          if (select && !processedSelects.has(select)) {
            languagesToAdd.forEach(lang => appendOption(select, lang, lang));
            sortOptions(select);
            processedSelects.add(select);
          }
        }
      });
    };

    /**
     * Populates options for web-related selectors from the WEB_CONFIG.
     */
    const populateWebOptions = () => {
      for (const selectorId in CONFIG.web) {
        const section = document.getElementById(selectorId);
        if (section) {
          const select = section.querySelector('select');
          if (select && !processedSelects.has(select)) {
            const optionGroup = CONFIG.web[selectorId];
            let optionsAdded = false;

            enabled.forEach(ext => {
              if (optionGroup[ext]) {
                optionGroup[ext].forEach(option => {
                  appendOption(select, option.text, option.value);
                  optionsAdded = true;
                });
              }
            });

            if (optionsAdded) {
              sortOptions(select);
            }
            processedSelects.add(select);
          }
        }
      }
    };

    populateAlgorithmLanguages();
    populateWebOptions();
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', run);
  } else {
    // The DOM is already ready.
    run();
  }
})();