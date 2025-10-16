// The Mechanic 2 - Inline JavaScript
// Provides UI functionality without external dependencies

(function() {
  'use strict';
  
  // Get the base path from the current URL
  const basePath = window.location.pathname.replace(/\/$/, '');
  
  // State management
  const state = {
    results: null,
    logs: null,
    isRunning: false,
    logsExpanded: false,
    activeLogTab: 'summary'
  };
  
  // Initialize the application
  function init() {
    setupEventListeners();
    initializeEditors();
  }
  
  // Setup event listeners
  function setupEventListeners() {
    // Validate button
    const validateBtn = document.getElementById('validate-btn');
    if (validateBtn) {
      validateBtn.addEventListener('click', handleValidate);
    }
    
    // Run button
    const runBtn = document.getElementById('run-btn');
    if (runBtn) {
      runBtn.addEventListener('click', handleRun);
    }
    
    // Reset button
    const resetBtn = document.getElementById('reset-btn');
    if (resetBtn) {
      resetBtn.addEventListener('click', handleReset);
    }
    
    // Logs toggle
    const logsToggle = document.getElementById('logs-toggle');
    if (logsToggle) {
      logsToggle.addEventListener('click', toggleLogs);
    }
    
    // Log tabs
    const logTabs = document.querySelectorAll('.log-tab');
    logTabs.forEach(tab => {
      tab.addEventListener('click', () => switchLogTab(tab.dataset.tab));
    });
  }
  
  // Initialize simple text editors (fallback if Monaco is not available)
  function initializeEditors() {
    // For now, use simple textareas
    // Monaco Editor can be added later if needed
    const sharedSetup = document.getElementById('shared-setup');
    const codeA = document.getElementById('code-a');
    const codeB = document.getElementById('code-b');
    
    if (sharedSetup) sharedSetup.style.fontFamily = 'Monaco, Menlo, monospace';
    if (codeA) codeA.style.fontFamily = 'Monaco, Menlo, monospace';
    if (codeB) codeB.style.fontFamily = 'Monaco, Menlo, monospace';
  }
  
  // Handle validate button click
  async function handleValidate() {
    clearMessages();
    
    const sharedSetup = document.getElementById('shared-setup').value;
    const codeA = document.getElementById('code-a').value;
    const codeB = document.getElementById('code-b').value;
    
    try {
      const response = await fetch(`${basePath}/validate`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          shared_setup: sharedSetup,
          code_a: codeA,
          code_b: codeB
        })
      });
      
      const data = await response.json();
      
      if (data.valid) {
        showSuccess('All code is valid and safe to run!');
      } else {
        showError('Validation failed', data.errors);
      }
    } catch (error) {
      showError('Validation error', [error.message]);
    }
  }
  
  // Handle run button click
  async function handleRun() {
    if (state.isRunning) return;
    
    clearMessages();
    hideResults();
    
    const sharedSetup = document.getElementById('shared-setup').value;
    const codeA = document.getElementById('code-a').value;
    const codeB = document.getElementById('code-b').value;
    const timeout = parseInt(document.getElementById('timeout').value) || 30;
    
    if (!codeA.trim() || !codeB.trim()) {
      showError('Missing code', ['Both Code A and Code B are required']);
      return;
    }
    
    setRunning(true);
    
    try {
      const response = await fetch(`${basePath}/run`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          shared_setup: sharedSetup,
          code_a: codeA,
          code_b: codeB,
          timeout: timeout
        })
      });
      
      const data = await response.json();
      
      if (response.ok) {
        state.results = data;
        displayResults(data);
        showSuccess('Benchmark completed successfully!');
      } else {
        showError(data.error || 'Benchmark failed', data.errors || [data.message]);
      }
    } catch (error) {
      showError('Benchmark error', [error.message]);
    } finally {
      setRunning(false);
    }
  }
  
  // Handle reset button click
  function handleReset() {
    if (confirm('Are you sure you want to reset? This will clear all inputs and results.')) {
      document.getElementById('shared-setup').value = '';
      document.getElementById('code-a').value = '';
      document.getElementById('code-b').value = '';
      document.getElementById('timeout').value = '30';
      clearMessages();
      hideResults();
      state.results = null;
      state.logs = null;
    }
  }
  

  
  // Display results
  function displayResults(data) {
    const resultsSection = document.getElementById('results-section');
    if (!resultsSection) return;
    
    resultsSection.classList.remove('hidden');
    
    // Display Code A metrics
    displayMetrics('code-a', data.code_a_metrics, data.winner === 'code_a');
    
    // Display Code B metrics
    displayMetrics('code-b', data.code_b_metrics, data.winner === 'code_b');
    
    // Display summary
    const summaryText = document.getElementById('summary-text');
    if (summaryText) {
      summaryText.textContent = data.summary;
    }
    
    // Show runtime logs section
    const logsSection = document.getElementById('runtime-logs-section');
    if (logsSection) {
      logsSection.classList.remove('hidden');
    }
    
    // Update log panels
    updateLogPanels(data);
  }
  
  // Display metrics for a code snippet
  function displayMetrics(codeId, metrics, isWinner) {
    const card = document.getElementById(`${codeId}-card`);
    if (!card) return;
    
    if (isWinner) {
      card.classList.add('winner');
    } else {
      card.classList.remove('winner');
    }
    
    const winnerBadge = card.querySelector('.winner-badge');
    if (winnerBadge) {
      winnerBadge.classList.toggle('hidden', !isWinner);
    }
    
    // Update metrics
    updateMetric(card, 'ips', formatNumber(metrics.ips));
    updateMetric(card, 'stddev', formatNumber(metrics.stddev));
    updateMetric(card, 'objects', formatNumber(metrics.objects));
    updateMetric(card, 'memory', formatNumber(metrics.memory_mb) + ' MB');
    updateMetric(card, 'time', formatNumber(metrics.execution_time) + ' sec');
  }
  
  // Update a single metric
  function updateMetric(card, metricName, value) {
    const element = card.querySelector(`[data-metric="${metricName}"]`);
    if (element) {
      element.textContent = value;
    }
  }
  
  // Format number for display
  function formatNumber(num) {
    if (num === null || num === undefined) return '0';
    
    if (typeof num === 'number') {
      if (num < 0.01) {
        return num.toFixed(6);
      } else if (num < 1) {
        return num.toFixed(4);
      } else if (num < 100) {
        return num.toFixed(2);
      } else {
        return Math.round(num).toLocaleString();
      }
    }
    
    return num.toString();
  }
  
  // Update log panels with benchmark data
  function updateLogPanels(data) {
    // Summary log
    const summaryLog = document.getElementById('summary-log');
    if (summaryLog) {
      summaryLog.textContent = `${data.summary}

Code A Performance:
  IPS: ${formatNumber(data.code_a_metrics.ips)} iterations/sec
  Std Dev: ±${formatNumber(data.code_a_metrics.stddev)}
  Objects: ${formatNumber(data.code_a_metrics.objects)}
  Memory: ${formatNumber(data.code_a_metrics.memory_mb)} MB
  Time: ${formatNumber(data.code_a_metrics.execution_time)} sec

Code B Performance:
  IPS: ${formatNumber(data.code_b_metrics.ips)} iterations/sec
  Std Dev: ±${formatNumber(data.code_b_metrics.stddev)}
  Objects: ${formatNumber(data.code_b_metrics.objects)}
  Memory: ${formatNumber(data.code_b_metrics.memory_mb)} MB
  Time: ${formatNumber(data.code_b_metrics.execution_time)} sec`;
    }
    
    // Benchmark log
    const benchmarkLog = document.getElementById('benchmark-log');
    if (benchmarkLog) {
      benchmarkLog.textContent = `Benchmark.ips Results:

Code A: ${formatNumber(data.code_a_metrics.ips)} i/s
Code B: ${formatNumber(data.code_b_metrics.ips)} i/s

Winner: ${data.winner === 'code_a' ? 'Code A' : data.winner === 'code_b' ? 'Code B' : 'Tie'}
Performance Ratio: ${data.performance_ratio}×`;
    }
    
    // Memory log
    const memoryLog = document.getElementById('memory-log');
    if (memoryLog) {
      memoryLog.textContent = `Memory Profiling Results:

Code A:
  Total Objects Allocated: ${formatNumber(data.code_a_metrics.objects)}
  Total Memory: ${formatNumber(data.code_a_metrics.memory_mb)} MB

Code B:
  Total Objects Allocated: ${formatNumber(data.code_b_metrics.objects)}
  Total Memory: ${formatNumber(data.code_b_metrics.memory_mb)} MB`;
    }
    
    // GC log
    const gcLog = document.getElementById('gc-log');
    if (gcLog) {
      gcLog.textContent = `Garbage Collection Statistics:

Note: GC statistics collection is not yet implemented.
This will show Ruby GC stats during benchmark execution.`;
    }
  }
  
  // Toggle logs visibility
  function toggleLogs() {
    state.logsExpanded = !state.logsExpanded;
    const logsContent = document.getElementById('logs-content');
    const logsToggle = document.getElementById('logs-toggle');
    const chevron = logsToggle?.querySelector('.logs-chevron');
    const toggleText = logsToggle?.querySelector('.logs-toggle-text');
    
    if (logsContent) {
      logsContent.classList.toggle('hidden');
    }
    
    if (chevron) {
      chevron.classList.toggle('expanded');
    }
    
    if (toggleText) {
      toggleText.textContent = state.logsExpanded ? 'Click to collapse' : 'Click to expand';
    }
    
    if (logsToggle) {
      logsToggle.setAttribute('aria-expanded', state.logsExpanded);
    }
  }
  
  // Switch log tab
  function switchLogTab(tabName) {
    state.activeLogTab = tabName;
    
    // Update tab buttons
    document.querySelectorAll('.log-tab').forEach(tab => {
      tab.classList.toggle('active', tab.dataset.tab === tabName);
    });
    
    // Update panels
    document.querySelectorAll('.log-panel').forEach(panel => {
      panel.classList.toggle('hidden', panel.dataset.panel !== tabName);
    });
  }
  
  // Set running state
  function setRunning(running) {
    state.isRunning = running;
    
    const runBtn = document.getElementById('run-btn');
    const validateBtn = document.getElementById('validate-btn');
    
    if (runBtn) {
      runBtn.disabled = running;
      runBtn.innerHTML = running ? 
        '<span class="loading-spinner"></span> Running...' : 
        'Run Benchmark';
    }
    
    if (validateBtn) {
      validateBtn.disabled = running;
    }
  }
  
  // Show success message
  function showSuccess(message) {
    const container = document.getElementById('message-container');
    if (!container) return;
    
    container.innerHTML = `
      <div class="success-message">
        ${message}
      </div>
    `;
  }
  
  // Show error message
  function showError(title, errors) {
    const container = document.getElementById('message-container');
    if (!container) return;
    
    const errorList = errors && errors.length > 0 ? `
      <ul class="error-list">
        ${errors.map(e => `<li>${e}</li>`).join('')}
      </ul>
    ` : '';
    
    container.innerHTML = `
      <div class="error-message">
        <strong>${title}</strong>
        ${errorList}
      </div>
    `;
  }
  
  // Clear messages
  function clearMessages() {
    const container = document.getElementById('message-container');
    if (container) {
      container.innerHTML = '';
    }
  }
  
  // Hide results
  function hideResults() {
    const resultsSection = document.getElementById('results-section');
    if (resultsSection) {
      resultsSection.classList.add('hidden');
    }
    
    const logsSection = document.getElementById('runtime-logs-section');
    if (logsSection) {
      logsSection.classList.add('hidden');
    }
  }
  
  // Initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
