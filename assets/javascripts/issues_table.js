document.addEventListener('DOMContentLoaded', () => {
    const selectAllCheckbox = document.getElementById('select-all-issues');
    const deleteButton = document.getElementById('delete-selected-issues');
    let issueCheckboxes;

    function initializeCheckboxes() {
        issueCheckboxes = document.querySelectorAll('.issue-checkbox');

        selectAllCheckbox?.addEventListener('change', () => {
            issueCheckboxes.forEach(checkbox => {
                checkbox.checked = selectAllCheckbox.checked;
            });
            toggleDeleteButton();
        });

        issueCheckboxes.forEach(checkbox => {
            checkbox.addEventListener('change', toggleDeleteButton);
        });
    }

    initializeCheckboxes();

    function toggleDeleteButton() {
        const hasChecked = Array.from(issueCheckboxes).some(checkbox => checkbox.checked);
        if (deleteButton) {
            deleteButton.style.display = hasChecked ? 'block' : 'none';
        }
    }

    deleteButton?.addEventListener('click', (e) => {
        e.preventDefault(); // Предотвращаем стандартное поведение

        const selectedIds = Array.from(issueCheckboxes)
            .filter(checkbox => checkbox.checked)
            .map(checkbox => checkbox.value);

        if (selectedIds.length === 0) {
            alert('Выберите хотя бы одну задачу.');
            return;
        }

        if (!confirm('Вы уверены, что хотите удалить выбранные задачи?')) {
            return;
        }

        const reportId = deleteButton.dataset.reportId;
        const token = document.querySelector('meta[name="csrf-token"]').content;

        $.ajax({
            url: `/reports/${reportId}/report_issues/remove_issues`,
            type: 'DELETE',
            data: { issue_ids: selectedIds },
            dataType: 'script',
            headers: {
                'X-CSRF-Token': token
            }
        }).fail(function() {
            alert('Произошла ошибка при удалении задач');
        });

        return false; // Дополнительно предотвращаем действие по умолчанию
    });
});