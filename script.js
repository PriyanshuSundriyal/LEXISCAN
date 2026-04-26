document.addEventListener('DOMContentLoaded', function () {
    const fileInput   = document.getElementById('file-input');
    const fileName    = document.getElementById('file-name');
    const analyzeBtn  = document.getElementById('analyze-btn');
    const outputSection = document.getElementById('output-section');
    const outputContent = document.getElementById('output-content');
    const downloadBtn = document.getElementById('download-btn');

    let inputFile    = null;
    let rawOutputText = '';

    const TYPE_COLORS = {
        'Keyword':                  '#6366f1',
        'Identifier':               '#0ea5e9',
        'Integer Constant':         '#f59e0b',
        'Floating Constant':        '#f59e0b',
        'Scientific Constant':      '#f59e0b',
        'Hexadecimal Constant':     '#f59e0b',
        'Octal Constant':           '#f59e0b',
        'Character Constant':       '#f97316',
        'String':                   '#10b981',
        'Preprocessor Directive':   '#8b5cf6',
        'Header File':              '#a855f7',
        'Single-line Comment':      '#94a3b8',
        'Multi-line Comment':       '#94a3b8',
        'Assignment Operator':      '#ec4899',
        'Arithmetic Operator':      '#ec4899',
        'Relational Operator':      '#ec4899',
        'Logical Operator':         '#ec4899',
        'Bitwise Operator':         '#ec4899',
        'Increment Operator':       '#ec4899',
        'Decrement Operator':       '#ec4899',
        'Arrow Operator':           '#ec4899',
        'Dot Operator':             '#ec4899',
        'Ternary Operator':         '#ec4899',
        'Ellipsis Operator':        '#ec4899',
        'Token Pasting Operator':   '#ec4899',
        'Stringizing Operator':     '#ec4899',
        'Delimiter':                '#14b8a6',
        'Escape Sequence':          '#f97316',
        'Standard Predefined Macro':'#8b5cf6',
        'Predefined Constant':      '#f59e0b',
        'Lexical Error':            '#ef4444',
    };

    fileInput.addEventListener('change', function (e) {
        inputFile = e.target.files[0];
        if (inputFile) {
            fileName.textContent = inputFile.name;
            analyzeBtn.disabled  = false;
        } else {
            fileName.textContent = 'No file selected';
            analyzeBtn.disabled  = true;
        }
    });

    analyzeBtn.addEventListener('click', async function () {
        if (!inputFile) return;

        analyzeBtn.textContent = 'Analyzing…';
        analyzeBtn.disabled    = true;

        const formData = new FormData();
        formData.append('file', inputFile);

        try {
            const response = await fetch('/analyze', { method: 'POST', body: formData });

            if (response.ok) {
                rawOutputText = await response.text();
                renderOutput(rawOutputText);
                outputSection.classList.remove('hidden');
                outputSection.classList.add('show');
            } else {
                alert('Analysis failed: ' + response.statusText);
            }
        } catch (err) {
            alert('Error: ' + err.message);
        }

        analyzeBtn.textContent = 'Perform Lexical Analysis';
        analyzeBtn.disabled    = false;
    });

    function renderOutput(text) {
        const lines   = text.split('\n').map(l => l.trimEnd());
        let   section = null;
        const tokens  = [];
        const summary = [];

        for (const line of lines) {
            if (line === '##TOKENS##')  { section = 'tokens';  continue; }
            if (line === '##SUMMARY##') { section = 'summary'; continue; }
            if (!line) continue;

            if (section === 'tokens') {
                if (line.startsWith('S.No|')) continue;

                const parts = splitPipe(line);
                if (parts.length >= 4) {
                    tokens.push({
                        sno:   parts[0],
                        type:  parts[1],
                        lexeme: parts[2],
                        lines: parts[3]
                    });
                }
            } else if (section === 'summary') {
                const idx = line.indexOf('|');
                if (idx !== -1) {
                    summary.push({ label: line.slice(0, idx), value: line.slice(idx + 1) });
                }
            }
        }

        outputContent.innerHTML = buildTable(tokens) + buildSummary(summary);
    }

    function splitPipe(line) {
        const parts = [];
        let cur = '';
        for (let i = 0; i < line.length; i++) {
            if (line[i] === '\\' && line[i + 1] === '|') {
                cur += '|'; i++;        // unescape
            } else if (line[i] === '|') {
                parts.push(cur); cur = '';
            } else {
                cur += line[i];
            }
        }
        parts.push(cur);
        return parts;
    }

    function buildTable(tokens) {
        if (!tokens.length) return '<p class="no-data">No tokens found.</p>';

        let html = `
        <div class="table-wrapper">
          <table class="token-table">
            <thead>
              <tr>
                <th>S.No</th>
                <th>Token Type</th>
                <th>Lexeme</th>
                <th>Line Numbers</th>
              </tr>
            </thead>
            <tbody>`;

        for (const t of tokens) {
            const color = TYPE_COLORS[t.type] || '#64748b';
            const isError = t.type === 'Lexical Error';
            html += `
              <tr class="${isError ? 'error-row' : ''}">
                <td class="sno-cell">${escHtml(t.sno)}</td>
                <td>
                  <span class="type-badge" style="background:${color}22;color:${color};border-color:${color}44">
                    ${escHtml(t.type)}
                  </span>
                </td>
                <td><code class="lexeme-code">${escHtml(t.lexeme)}</code></td>
                <td class="lines-cell">${escHtml(t.lines)}</td>
              </tr>`;
        }

        html += `</tbody></table></div>`;
        return html;
    }

    function buildSummary(summary) {
        if (!summary.length) return '';

        const ICONS = {
            'Keywords':                 '🔑',
            'Identifiers':              '🏷️',
            'Constants':                '🔢',
            'Operators':                '⚙️',
            'Delimiters':               '📌',
            'Comments':                 '💬',
            'Preprocessor Directives':  '📦',
            'Header Files':             '📂',
            'Lexical Errors':           '❌',
            'Total Lexemes':            '📊',
            'Valid Tokens':             '✅',
        };

        let html = '<div class="summary-section"><h3 class="summary-title">Token Summary</h3><div class="summary-grid">';
        for (const s of summary) {
            const icon    = ICONS[s.label] || '📋';
            const isError = s.label === 'Lexical Errors' && parseInt(s.value) > 0;
            const isTotal = s.label === 'Total Lexemes' || s.label === 'Valid Tokens';
            html += `
            <div class="summary-card ${isError ? 'error-card' : ''} ${isTotal ? 'total-card' : ''}">
              <span class="summary-icon">${icon}</span>
              <span class="summary-value">${escHtml(s.value)}</span>
              <span class="summary-label">${escHtml(s.label)}</span>
            </div>`;
        }
        html += '</div></div>';
        return html;
    }

    function escHtml(str) {
        return String(str)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }

    downloadBtn.addEventListener('click', function () {
        const text = buildPlainText(rawOutputText);
        const blob = new Blob([text], { type: 'text/plain' });
        const url  = URL.createObjectURL(blob);
        const a    = document.createElement('a');
        a.href     = url;
        a.download = 'output.txt';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    });

    function buildPlainText(text) {
        const lines   = text.split('\n').map(l => l.trimEnd());
        let   section = null;
        const tokens  = [];
        const summary = [];

        for (const line of lines) {
            if (line === '##TOKENS##')  { section = 'tokens';  continue; }
            if (line === '##SUMMARY##') { section = 'summary'; continue; }
            if (!line) continue;

            if (section === 'tokens') {
                if (line.startsWith('S.No|')) continue;
                const parts = splitPipe(line);
                if (parts.length >= 4)
                    tokens.push({ sno: parts[0], type: parts[1], lexeme: parts[2], lines: parts[3] });
            } else if (section === 'summary') {
                const idx = line.indexOf('|');
                if (idx !== -1)
                    summary.push({ label: line.slice(0, idx), value: line.slice(idx + 1) });
            }
        }

        const W = {
            sno:    Math.max('S.No'.length,          ...tokens.map(t => t.sno.length)),
            type:   Math.max('Token Type'.length,    ...tokens.map(t => t.type.length)),
            lexeme: Math.max('Lexeme'.length,        ...tokens.map(t => t.lexeme.length)),
            lines:  Math.max('Line Numbers'.length,  ...tokens.map(t => t.lines.length)),
        };

        const GAP  = 4;
        const pad  = (s, w) => String(s).padEnd(w);
        const dash = (w)    => '-'.repeat(w);
        const totalW = W.sno + W.type + W.lexeme + W.lines + GAP * 3;

        let out = '';
        out += 'LEXISCAN - C Language Lexical Analyzer\n';
        out += '='.repeat(totalW) + '\n\n';

        out += pad('S.No', W.sno)         + ' '.repeat(GAP)
             + pad('Token Type', W.type)  + ' '.repeat(GAP)
             + pad('Lexeme', W.lexeme)    + ' '.repeat(GAP)
             + 'Line Numbers\n';

        out += dash(W.sno)    + ' '.repeat(GAP)
             + dash(W.type)   + ' '.repeat(GAP)
             + dash(W.lexeme) + ' '.repeat(GAP)
             + dash(W.lines)  + '\n';

        for (const t of tokens) {
            out += pad(t.sno,    W.sno)    + ' '.repeat(GAP)
                 + pad(t.type,   W.type)   + ' '.repeat(GAP)
                 + pad(t.lexeme, W.lexeme) + ' '.repeat(GAP)
                 + t.lines + '\n';
        }

        out += '\n';

        const labelW = Math.max(...summary.map(s => s.label.length));
        out += 'TOKEN SUMMARY\n';
        out += dash(labelW + 10) + '\n';
        for (const s of summary) {
            out += pad(s.label, labelW) + '    ' + s.value + '\n';
        }
        out += dash(labelW + 10) + '\n';

        return out;
    }
});
