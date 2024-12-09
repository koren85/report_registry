$(document).ready(function() {
    const periodSelect = $('#report_period');
    const monthlyFields = $('#monthly_fields');
    const quarterlyFields = $('#quarterly_fields');
    const yearlyFields = $('#yearly_fields');
    const customDateFields = $('#custom_date_fields');
    const contractInput = $('#report_contract_number');

    const monthSelect = $('#month_select');
    const quarterSelect = $('#quarter_select');
    const yearSelects = $('.period-select[id^="year_select"]');

    const hiddenStartDate = $('#hidden_start_date');
    const hiddenEndDate = $('#hidden_end_date');

    // Обработчики изменения периода и его значений
    periodSelect.on('change', function() {
        const period = $(this).val();

        // Скрываем все поля
        monthlyFields.hide();
        quarterlyFields.hide();
        yearlyFields.hide();
        customDateFields.hide();

        // Показываем нужные поля
        switch(period) {
            case 'месячный':
                monthlyFields.show();
                break;
            case 'квартальный':
                quarterlyFields.show();
                break;
            case 'годовой':
                yearlyFields.show();
                break;
            case 'прочее':
                customDateFields.show();
                break;
        }

        updateHiddenDates();
        updateReportName(); // Обновляем название при изменении типа периода
    });

    // Добавляем обработчики для всех селектов периода
    $('.period-select').on('change', function() {
        updateHiddenDates();
        updateReportName(); // Обновляем название при изменении значения периода
    });

    // Добавляем обработчик для номера контракта
    contractInput.on('input', function() {
        updateReportName(); // Обновляем название при изменении номера контракта
    });

    $('#report_start_date, #report_end_date').on('change', function() {
        updateHiddenDates();
        updateReportName();
    });

    // Функция получения последнего дня месяца
    function getLastDayOfMonth(year, month) {
        return new Date(year, month, 0).getDate();
    }

    // Функция форматирования даты в формат YYYY-MM-DD
    function formatDate(date) {
        return date.toISOString().split('T')[0];
    }

    // Функция обновления скрытых полей дат
    function updateHiddenDates() {
        const period = periodSelect.val();
        const year = parseInt($(':visible[id^="year_select"]').val());

        let startDate, endDate;

        switch(period) {
            case 'месячный':
                const month = parseInt(monthSelect.val());
                startDate = new Date(year, month - 1, 1);
                endDate = new Date(year, month - 1, getLastDayOfMonth(year, month));
                break;

            case 'квартальный':
                const quarter = parseInt(quarterSelect.val());
                startDate = new Date(year, (quarter - 1) * 3, 1);
                endDate = new Date(year, quarter * 3 - 1, getLastDayOfMonth(year, quarter * 3));
                break;

            case 'годовой':
                startDate = new Date(year, 0, 1);
                endDate = new Date(year, 11, 31);
                break;

            case 'прочее':
                startDate = $('#report_start_date').val();
                endDate = $('#report_end_date').val();
                break;
        }

        if (startDate && endDate) {
            hiddenStartDate.val(typeof startDate === 'string' ? startDate : formatDate(startDate));
            hiddenEndDate.val(typeof endDate === 'string' ? endDate : formatDate(endDate));
        }
    }

    // Инициализация при загрузке
    initializeDateFields();
});