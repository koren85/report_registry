// plugins/report_registry/assets/javascripts/modal_issues_handler.js
var IssuesModalHandler = (function() {
    var currentSort = { column: 'id', direction: 'desc' };
    var searchTimeout;

    function initialize() {
        attachEventHandlers();
    }

    function attachEventHandlers() {
        $(document).on('input', '#issues-search-input', handleSearch);
        $(document).on('click', '.sort', handleSort);
        $(document).on('change', '.toggle-selection', handleToggleAll);
    }

    function handleSearch() {
        var searchValue = $(this).val();
        var $modal = $(this).closest('.box');

        clearTimeout(searchTimeout);
        searchTimeout = setTimeout(function() {
            fetchIssues(searchValue, currentSort.column, currentSort.direction, $modal);
        }, 300);
    }

    function handleSort(e) {
        e.preventDefault();
        var column = $(this).data('sort');
        var $modal = $(this).closest('.box');

        if (currentSort.column === column) {
            currentSort.direction = currentSort.direction === 'asc' ? 'desc' : 'asc';
        } else {
            currentSort.column = column;
            currentSort.direction = 'asc';
        }

        $('.sort').removeClass('sorted-asc sorted-desc');
        $(this).addClass('sorted-' + currentSort.direction);

        fetchIssues($('#issues-search-input').val(), currentSort.column, currentSort.direction, $modal);
    }

    function handleToggleAll() {
        var isChecked = $(this).prop('checked');
        $(this).closest('table').find('tbody input[type="checkbox"]').prop('checked', isChecked);
    }

    function fetchIssues(searchValue, sortColumn, sortDirection, $modal) {
        var $searchInput = $('#issues-search-input');
        var url = $searchInput.data('url').replace('.json', '');
        var $tbody = $modal.find('.issues-list');
        var $loadingIndicator = $('<div class="loading">Загрузка...</div>');

        if (!url) {
            console.error('Search URL is missing');
            return;
        }

        $tbody.before($loadingIndicator);

        $.ajax({
            url: url,
            type: 'get',
            data: {
                q: searchValue,
                sort: sortColumn,
                direction: sortDirection
            },
            success: function(response) {
                $tbody.empty().append(response);
            },
            error: function(xhr, status, error) {
                console.error('Error fetching issues:', error);
                if (xhr.status === 401) {
                    // Если ошибка авторизации, перезагружаем страницу
                    window.location.reload();
                } else {
                    alert(xhr.responseText || 'Ошибка при получении списка задач');
                }
            },
            complete: function() {
                $loadingIndicator.remove();
            }
        });
    }

    return {
        initialize: initialize
    };
})();

// Инициализация при загрузке модального окна
$(document).ready(function() {
    if ($('#ajax-modal').length) {
        IssuesModalHandler.initialize();
    }
});