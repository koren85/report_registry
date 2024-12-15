$(document).ready(function() {
    // DOM элементы - кэшируем все jQuery объекты
    const $periodSelect = $('#report_period');
    const $monthlyFields = $('#monthly_fields');
    const $quarterlyFields = $('#quarterly_fields');
    const $yearlyFields = $('#yearly_fields');
    const $customDateFields = $('#custom_date_fields');
    const $contractInput = $('#report_contract_number');

    const $monthSelect = $('#month_select');
    const $quarterSelect = $('#quarter_select');
    const $yearSelects = $('.period-select[id^="year_select"]');

    const $hiddenStartDate = $('#hidden_start_date');
    const $hiddenEndDate = $('#hidden_end_date');
    const $startDate = $('#report_start_date');
    const $endDate = $('#report_end_date');

    // Функция инициализации полей дат
    function initializeDateFields() {
        const period = $periodSelect.val();

        // Скрываем все поля
        $monthlyFields.hide();
        $quarterlyFields.hide();
        $yearlyFields.hide();
        $customDateFields.hide();

        // Показываем нужные поля
        switch(period) {
            case 'месячный':
                $monthlyFields.show();
                break;
            case 'квартальный':
                $quarterlyFields.show();
                break;
            case 'годовой':
                $yearlyFields.show();
                break;
            case 'прочее':
                $customDateFields.show();
                break;
        }

        updateHiddenDates();
        updateReportName(); // Обновляем название при инициализации
    }

    // Обработчики событий
    $periodSelect.on('change', function() {
        initializeDateFields();
    });

    // Обработчики для всех селектов периода
    $('.period-select').on('change', function() {
        updateHiddenDates();
        updateReportName();
    });

    // Обработчик для номера контракта
    $contractInput.on('input', function() {
        updateReportName();
    });

    // Обработчики для полей дат
    $startDate.add($endDate).on('change', function() {
        updateHiddenDates();
        updateReportName();
    });

    // Вспомогательные функции
    function getLastDayOfMonth(year, month) {
        return new Date(year, month, 0).getDate();
    }

    function formatDate(date) {
        return date.toISOString().split('T')[0];
    }

    // Функция обновления скрытых полей дат
    function updateHiddenDates() {
        const period = $periodSelect.val();
        const year = parseInt($(':visible[id^="year_select"]').val());

        let startDate, endDate;

        switch(period) {
            case 'месячный':
                const month = parseInt($monthSelect.val());
                startDate = new Date(year, month - 1, 1);
                endDate = new Date(year, month - 1, getLastDayOfMonth(year, month));
                break;

            case 'квартальный':
                const quarter = parseInt($quarterSelect.val());
                startDate = new Date(year, (quarter - 1) * 3, 1);
                endDate = new Date(year, quarter * 3 - 1, getLastDayOfMonth(year, quarter * 3));
                break;

            case 'годовой':
                startDate = new Date(year, 0, 1);
                endDate = new Date(year, 11, 31);
                break;

            case 'прочее':
                startDate = $startDate.val();
                endDate = $endDate.val();
                break;
        }

        if (startDate && endDate) {
            $hiddenStartDate.val(typeof startDate === 'string' ? startDate : formatDate(startDate));
            $hiddenEndDate.val(typeof endDate === 'string' ? endDate : formatDate(endDate));
        }
    }

    // Запускаем инициализацию при загрузке
    initializeDateFields();
});