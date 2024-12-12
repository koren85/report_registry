$(document).ready(function() {
    // DOM элементы - кэшируем все jQuery объекты
    const $document = $(document);
    const $body = $('body');
    const $projectSelect = $('#project-select');
    const $reportForm = $('#report-form');
    const $reportIssuesBody = $('#report-issues-body');
    const $modal = $('#add-issues-modal');
    const $modalOverlay = $('#modal-overlay');
    const $issuesSearchInput = $('#issues-search');
    const $searchResults = $('#issues-search-results');
    const $selectAllCheckbox = $('#select-all-issues');
    const $sortableHeaders = $('.sortable');
    const $addSelectedBtn = $('#add-selected-issues');

    // Состояние
    let searchTimeout;
    let currentSort = { column: 'id', direction: 'asc' };
    let selectedIssues = new Set();

    // Инициализация
    initializeEventHandlers();
    loadReportIssues();

    function initializeEventHandlers() {
        // Обработчики для модального окна
        $document
            .on('click', '#add-issues-btn', (e) => {
                e.preventDefault();
                e.stopPropagation();
                openModal();
            })
            .on('click', '.close-modal, #cancel-add-issues', (e) => {
                e.preventDefault();
                e.stopPropagation();
                closeModal();
            })
            .on('keydown', (e) => {
                if (e.key === 'Escape' && $modal.is(':visible')) {
                    closeModal();
                }
            });

        // Предотвращаем закрытие при клике внутри модального окна
        $modal.on('click', (e) => e.stopPropagation());

        // Закрытие по клику на оверлей
        $modalOverlay.on('click', closeModal);

        // Поиск и выбор задач
        $issuesSearchInput.on('input', debounce(handleSearch, 300));
        $selectAllCheckbox.on('change', handleSelectAll);
        $searchResults.on('change', '.issue-checkbox', handleCheckboxChange);
        $addSelectedBtn.on('click', handleAddSelected);

        // Обработчики таблицы задач
        $reportIssuesBody
            .on('click', '.remove-issue', handleRemoveIssue);

        $sortableHeaders.on('click', handleSort);

        // Изменение проекта
        $projectSelect.on('change', function() {
            $reportIssuesBody.empty();
            loadReportIssues();
            if ($modal.is(':visible')) {
                closeModal();
            }
        });
    }

    function openModal() {
        // Перемещаем модальное окно в конец body
        if (!$modal.parent().is('body')) {
            $modal.appendTo($body);
            $modalOverlay.appendTo($body);
        }

        clearModal();
        $modalOverlay.show();
        $modal.show();
        $body.css('overflow', 'hidden');
        $issuesSearchInput.focus();
    }

    function closeModal() {
        $modalOverlay.hide();
        $modal.hide();
        $body.css('overflow', '');
        clearModal();
    }

    function clearModal() {
        $issuesSearchInput.val('');
        $searchResults.empty();
        $selectAllCheckbox.prop('checked', false);
        selectedIssues.clear();
    }

    function loadReportIssues() {
        const reportId = $reportForm.data('report-id');
        if (!reportId) return;

        $.ajax({
            url: `/reports/${reportId}/report_issues`,
            method: 'GET',
            beforeSend: showReportIssuesLoading,
            success: renderReportIssues,
            error: showReportIssuesError
        });
    }

    function showReportIssuesLoading() {
        $reportIssuesBody.html(`
            <tr><td colspan="10" class="text-center">
                <span class="loading">${I18n.t('text_loading')}</span>
            </td></tr>
        `);
    }

    function showReportIssuesError(xhr) {
        const errorMessage = xhr.responseJSON?.error || I18n.t('error_loading_issues');
        $reportIssuesBody.html(`
            <tr><td colspan="10" class="text-center text-error">
                ${errorMessage}
            </td></tr>
        `);
    }

    function renderReportIssues(issues) {
        $reportIssuesBody.empty();

        if (!issues?.length) {
            $reportIssuesBody.html(`
                <tr><td colspan="10" class="text-center">
                    ${I18n.t('text_no_issues_in_report')}
                </td></tr>
            `);
            return;
        }

        const rows = issues.map(issue => createIssueRow(issue));
        $reportIssuesBody.append(rows);
    }

    function createIssueRow(issue) {
        return $('<tr>').append(
            $('<td>').text(issue.id),
            $('<td>').text(issue.subject),
            $('<td>').text(issue.status),
            $('<td>').text(issue.project),
            $('<td>').text(issue.version || ''),
            $('<td>').text(formatDate(issue.start_date)),
            $('<td>').text(formatDate(issue.due_date)),
            $('<td>').text(issue.parent_issue || ''),
            $('<td>').text(issue.custom_field_value || ''),
            $('<td>').html(createRemoveButton(issue.id))
        );
    }

    function handleSearch() {
        const query = $issuesSearchInput.val().trim();

        if (query.length < 2) {
            showSearchMessage(I18n.t('text_search_min_chars'));
            return;
        }

        performSearch(query);
    }

    function showSearchMessage(message) {
        $searchResults.html(`
            <tr><td colspan="7" class="text-center">
                ${message}
            </td></tr>
        `);
    }

    function performSearch(query) {
        const reportId = $reportForm.data('report-id');

        $.ajax({
            url: `/reports/${reportId}/report_issues/search`,
            data: { q: query },
            beforeSend: () => showSearchMessage(I18n.t('text_loading')),
            success: renderSearchResults,
            error: xhr => showSearchMessage(xhr.responseJSON?.error || I18n.t('error_searching_issues'))
        });
    }

    function renderSearchResults(issues) {
        $searchResults.empty();

        if (!issues?.length) {
            showSearchMessage(I18n.t('text_no_issues_found'));
            return;
        }

        const rows = issues.map(issue => createSearchRow(issue));
        $searchResults.append(rows);
    }

    function createSearchRow(issue) {
        return $('<tr>').append(
            $('<td>').html(createCheckbox(issue.id)),
            $('<td>').text(issue.id),
            $('<td>').text(issue.subject),
            $('<td>').text(issue.status),
            $('<td>').text(issue.version || ''),
            $('<td>').text(formatDate(issue.start_date)),
            $('<td>').text(formatDate(issue.due_date))
        );
    }

    function handleSelectAll() {
        const isChecked = $selectAllCheckbox.prop('checked');
        const $checkboxes = $searchResults.find('.issue-checkbox');
        $checkboxes.prop('checked', isChecked);

        if (isChecked) {
            $checkboxes.each((_, el) => selectedIssues.add($(el).val()));
        } else {
            selectedIssues.clear();
        }
    }

    function handleCheckboxChange() {
        const $checkbox = $(this);
        const issueId = $checkbox.val();

        if ($checkbox.prop('checked')) {
            selectedIssues.add(issueId);
        } else {
            selectedIssues.delete(issueId);
        }

        updateSelectAllState();
    }

    function updateSelectAllState() {
        const $checkboxes = $searchResults.find('.issue-checkbox');
        const allChecked = $checkboxes.length > 0 &&
            $checkboxes.length === $checkboxes.filter(':checked').length;
        $selectAllCheckbox.prop('checked', allChecked);
    }

    function handleAddSelected(e) {
        e.preventDefault();

        if (selectedIssues.size === 0) {
            alert(I18n.t('text_no_issues_selected'));
            return;
        }

        const reportId = $reportForm.data('report-id');
        $.ajax({
            url: `/reports/${reportId}/report_issues/add_issues`,
            method: 'POST',
            data: { issue_ids: Array.from(selectedIssues) },
            success: () => {
                closeModal();
                loadReportIssues();
            },
            error: xhr => alert(xhr.responseJSON?.error || I18n.t('error_adding_issues'))
        });
    }

    function handleRemoveIssue(e) {
        e.preventDefault();
        const issueId = $(e.currentTarget).data('issue-id');
        const reportId = $reportForm.data('report-id');

        if (confirm(I18n.t('text_confirm_remove_issue'))) {
            $.ajax({
                url: `/reports/${reportId}/report_issues/remove_issue`,
                method: 'DELETE',
                data: { issue_id: issueId },
                success: loadReportIssues,
                error: xhr => alert(xhr.responseJSON?.error || I18n.t('error_removing_issue'))
            });
        }
    }

    function handleSort(e) {
        e.preventDefault();
        const $header = $(e.currentTarget);
        const column = $header.data('sort');

        $sortableHeaders.removeClass('sort-asc sort-desc');

        if (currentSort.column === column) {
            currentSort.direction = currentSort.direction === 'asc' ? 'desc' : 'asc';
        } else {
            currentSort.column = column;
            currentSort.direction = 'asc';
        }

        $header.addClass(`sort-${currentSort.direction}`);
        loadReportIssues();
    }

    function formatDate(dateString) {
        if (!dateString) return '';
        return new Date(dateString).toLocaleDateString();
    }

    function createCheckbox(issueId) {
        return `<input type="checkbox" class="issue-checkbox" value="${issueId}"
                ${selectedIssues.has(issueId) ? 'checked' : ''}>`;
    }

    function createRemoveButton(issueId) {
        return `<a href="#" class="icon icon-del remove-issue" data-issue-id="${issueId}">
            ${I18n.t('button_delete')}
        </a>`;
    }

    function debounce(func, wait) {
        let timeout;
        return function(...args) {
            clearTimeout(timeout);
            timeout = setTimeout(() => func.apply(this, args), wait);
        };
    }
});