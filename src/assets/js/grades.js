/**
 * Copyright (c) 2025 Helium Edu
 *
 * JavaScript functionality for persistence and the HeliumGrades object on the /planner/grades page.
 *
 * Be aware that this is legacy code, and we would love to have the capacity to completely rewrite it.
 * The way JavaScript and Ajax are being used is pretty dated. Are you a frontend expert in search of an open source
 * project and interested in joining forces? Reach out and let us know! contact@alexlaird.com
 *
 * @license MIT
 * @version 1.16.0
 */

/**
 * Create the HeliumGrades persistence object.
 *
 * @constructor construct the HeliumClasses persistence object
 */
function HeliumGrades() {
    "use strict";

    this.course_groups = {};
    this.courses = {};
    this.categories = {};
    this.today = new Date();
    this.series_legend = {}

    /*******************************************
     * Functions
     ******************************************/
    this.get_trend_arrow = function (trend) {
        return trend !== null ? (parseFloat(trend) > 0 ? " <span class=\"icon-x arrow-up-icon light-green\"></span>"
                                                       : " <span class=\"icon-x arrow-down-icon light-red\"></span>")
                              : "";
    };

    this.pie_hover = function (event, pos, item) {
        if (item) {
            $(this).qtip(
                {
                    content: item.series.label,
                    position: {
                        target: [pos.pageX, pos.pageY],
                        adjust: {
                            x: 5,
                            y: 5
                        },
                    },
                    show: true,
                    style: {classes: "qtip-bootstrap hidden-print"}
                });
        } else {
            $(this).qtip("hide", helium.QTIP_HIDE_INTERVAL);
        }
    };

    /**
     * Add the given course group's data to the page.
     *
     * @param data the data for the course group to be added
     */
    this.add_course_group_to_page = function (data) {
        if (helium.data_has_err_msg(data)) {
            helium.ajax_error_occurred = true;
            $("#loading-grades").spin(false);

            bootbox.alert(helium.get_error_msg(data));
        } else {
            $("#course-group-tabs").prepend('<li><a data-toggle="tab" href="#course-group-container-' + data.id
                                            + '"><i class="icon-list r-110"></i> <span class="hidden-xs">' + data.title
                                            + (!data.shown_on_calendar ? "</span> <i class=\"icon-eye-close\"></i>"
                                                                       : "</span>")
                                            + '</a></li>');
            const container = $('<div id="course-group-container-' + data.id + '" class="tab-pane"></div>');
            const details = $(
                '<div id="details-for-course-group-' + data.id + '" class="col-sm-12 infobox-container">');
            container.append(details);
            $("#course-group-tab-content").append(container);

            let days_remaining = data.num_days - data.num_days_completed;
            if (days_remaining < 0) {
                days_remaining = 0;
            }
            let percent_thru = (data.num_days_completed / data.num_days) * 100;
            if (percent_thru > 100) {
                percent_thru = 100;
            }
            if (isNaN(percent_thru)) {
                percent_thru = 0;
            }
            let percent_completed = (data.num_homework_completed / data.num_homework) * 100;
            if (percent_completed > 100) {
                percent_completed = 100;
            }
            if (isNaN(percent_completed)) {
                percent_completed = 0;
            }

            details.append('<div class="infobox infobox-blue2">' + percent_thru.toFixed()
                           + '<div class="infobox-progress"><div class="easy-pie-chart percentage easyPieChart" data-percent="'
                           + percent_thru.toFixed()
                           + '" data-size="46" style="width: 46px; height: 46px; line-height: 46px;"> <span class="percent">'
                           + percent_thru.toFixed()
                           + '</span>% <canvas width="46" height="46"></canvas></div></div><div class="infobox-data" id="thru-term"><span class="infobox-text">thru term</span><div class="infobox-content">'
                           + days_remaining + ' days remaining</div></div>');
            details.append(
                '<div class="infobox infobox-red"><div class="infobox-icon"><i class="icon-bookmark"></i></div><div class="infobox-data" id="num-assignments"><span class="infobox-data-number">'
                + data.num_homework + '</span><div class="infobox-content">assignments</div></div></div>');
            details.append(
                '<div class="infobox infobox-red"><div class="infobox-icon"><i class="icon-cogs"></i></div><div class="infobox-data" id="num-assignments-graded"><span class="infobox-data-number">'
                + data.num_homework_graded + '</span><div class="infobox-content">graded</div></div></div>');
            details.append('<div class="infobox infobox-blue2" id="thru-assignments">' + percent_completed.toFixed()
                           + '<div class="infobox-progress"><div class="easy-pie-chart percentage easyPieChart" data-percent="'
                           + percent_completed.toFixed()
                           + '" data-size="46" style="width: 46px; height: 46px; line-height: 46px;"><span class="percent">'
                           + percent_completed.toFixed()
                           + '</span>%<canvas width="46" height="46"></canvas></div></div><div class="infobox-data"><span class="infobox-text">'
                           + data.num_homework_completed + ' complete</span><div class="infobox-content">'
                           + (data.num_homework - data.num_homework_completed)
                           + ' remaining</div></div></div><div class="space-20"></div></div>');
            container.append(
                '<div class="row"><div class="col-xs-12"><div class="widget-box transparent"><div class="widget-header widget-header-flat"><h4 class="lighter"><i class="icon-bar-chart"></i><span id="time-series-header"> Term Progress</h4><span class="hidden-xs"> | </span><small class="hidden-xs" id="time-series-date"><span>'
                + moment(data.start_date, helium.HE_DATE_STRING_SERVER).format(helium.HE_DATE_STRING_CLIENT)
                + "</span> to <span>"
                + moment(data.end_date, helium.HE_DATE_STRING_SERVER).format(helium.HE_DATE_STRING_CLIENT)
                + "</span></small></span>"
                + '<a class="cursor-hover" data-action="collapse"><div class="widget-toolbar"><span class="badge" style=\"background-color: '
                + helium.USER_PREFS.settings.grade_color + ' !important">'
                + (parseFloat(data.overall_grade) != -1 ? (parseFloat(data.overall_grade).toFixed(2) + '% '
                + helium.grades.get_trend_arrow(data.trend)) : "N/A")
                + '</span> <i class="icon-chevron-up"></i></div></a></div><div class="widget-body"><div class="widget-main">'
                + '<div id="course-group-time-series-' + data.id + '"></div></div></div></div></div></div>');
            container.append(
                '<div class="row"><div class="col-xs-12" id="course-group-piechart-' + data.id + '"></div></div>');
        }
    };

    this.populate_time_series = function (course_group_id, items) {
        const time_series_tag = $("#course-group-time-series-" + course_group_id);
        time_series_tag.css({"width": "100%", "height": "220px"});

        if (items.length <= 1) {
            time_series_tag.parent().parent().parent().remove();
            $("#details-for-course-group-" + course_group_id).after(
                "<div class=\"row\"><div class=\"col-xs-12 col-sm-8 col-sm-offset-2 col-xs-12 well\">We can't calculate any grades for you if you don't have both <a href=\"/planner/classes\">classes</a> and <a href=\"/planner/calendar\">assignments</a>. Once you have those, head back here to see your grade progress!</div></div>");
            return;
        }

        let time_series_data = [], time_series_details = {
            shadowSize: 0,
            xaxis: {
                tickLength: 0,
                mode: "time",
                minTickSize: [1, "day"]
            },
            yaxis: {
                ticks: 5,
                min: 50,
                max: 100,
                tickFormatter: function (val) {
                    return val + "%&nbsp;";
                }
            },
            grid: {
                backgroundColor: {colors: ["#fff", "#fff"]},
                borderWidth: 1,
                borderColor: "#555",
                hoverable: true,
                clickable: true,
                markings: [{
                    xaxis: {from: helium.grades.today, to: helium.grades.today},
                    color: "#ff0000",
                    lineWidth: 1
                }]
            },
            legend: {
                show: true,
                position: "se",
                backgroundOpacity: 0.8,
                labelFormatter: function (label, series) {
                    let checked;
                    if (helium.grades.series_legend[series.course_group_id][series.type + '-' + series.id]) {
                        checked = "checked=\"checked\"";
                    } else {
                        checked = '';
                    }

                    return '<label><input type="checkbox" id="legend-' + series.type + '-' + series.id
                           + '" class="ace" ' + checked
                           + '/><span class="lbl smaller-80"> <span class="color-dot inline" style="background-color: '
                           + series.color + '\"/>' + label + '</span></label>';
                }
            }
        }

        $.each(items, function (i, item) {
            let data = [];
            $.each(item['grade_points'], function (i, grade) {
                data.push(
                    [
                        new Date(grade[0]),
                        grade[1],
                        {
                            id: grade[2],
                            title: grade[3],
                            grade: grade[4],
                            category_id: grade[5]
                        }
                    ]);
            });

            time_series_data.push(
                {
                    id: item.id,
                    type: item.type,
                    course_group_id: item.course_group_id,
                    label: "&nbsp;" + item.title,
                    data: data,
                    color: item.color,
                    lines: {
                        show: helium.grades.series_legend[course_group_id][item.type + '-' + item.id]
                    },
                    points: {
                        show: helium.grades.series_legend[course_group_id][item.type + '-' + item.id]
                    }
                });
        });

        time_series_tag.bind("plothover", function (event, pos, item) {
            if (item) {
                if (!helium.grades.hovered_item ||
                    (item.seriesIndex !== helium.grades.hovered_item.seriesIndex
                     && item.dataIndex !== helium.grades.hovered_item.dataIndex)) {
                    helium.grades.hovered_item = item;

                    $(this).css('cursor', 'pointer');
                    const point_data = item.series.data[item.dataIndex];
                    const homework_grade = (Math.round(point_data[2].grade * 100)
                                            / 100) + "%";
                    const point_grade = (Math.round(point_data[1] * 100) / 100)
                                        + "%";

                    time_series_tag.qtip(
                        {
                            position: {
                                target: [pos.pageX, pos.pageY],
                                adjust: {
                                    x: 5,
                                    y: 5
                                },
                            },
                            content: point_data[2].title
                                     + " <span class=\"color-dot inline\" style=\"background-color: "
                                     + helium.grades.categories[point_data[2].category_id].color
                                     + "\"></span> (" + homework_grade
                                     + ")<br/>Class Grade: "
                                     + point_grade,
                            show: true,
                            style: {classes: "qtip-bootstrap hidden-print"}
                        });
                }
            } else {
                $(this).css('cursor', 'default');
                helium.grades.hovered_item = null;
                time_series_tag.qtip('hide', helium.QTIP_HIDE_INTERVAL);
            }
        });

        time_series_tag.bind("plotclick", function (event, pos, item) {
            if (item) {
                const point_data = item.series.data[item.dataIndex];
                const homework_id = point_data[2].id;
                localStorage.setItem("edit_calendar_item", homework_id);
                window.location = "/planner/calendar";
            }
        });

        $.plot("#course-group-time-series-" + course_group_id, time_series_data, time_series_details);

        $("#course-group-time-series-" + course_group_id + " .legendLabel input").change(function () {
            let split = $(this).attr("id").split("-");
            helium.grades.series_legend[course_group_id][split[1] + "-" + split[2]] = $(this).is(":checked");

            helium.grades.populate_time_series(course_group_id, items);
        });
    }
}

// Initialize HeliumGrades and give a reference to the Helium object
helium.grades = new HeliumGrades();

/*******************************************
 * jQuery initialization
 ******************************************/

$(document).ready(function () {
    "use strict";

    $("#loading-grades").spin(helium.SMALL_LOADING_OPTS);

    bootbox.setDefaults({
                            locale: 'en'
                        });

    /*******************************************
     * Other page initialization
     ******************************************/
    $.when.apply($, helium.ajax_calls).done(function () {
        helium.ajax_calls.push(
            helium.planner_api.get_course_groups(function (data) {
                if (helium.data_has_err_msg(data)) {
                    helium.ajax_error_occurred = true;
                    $("#loading-grades").spin(false);

                    bootbox.alert(helium.get_error_msg(data));
                } else {
                    $.each(data, function (i, course_group) {
                        helium.grades.course_groups[course_group.id] = course_group;
                        helium.grades.course_groups[course_group.id].type = "course_group";

                        helium.grades.add_course_group_to_page(course_group);
                    });
                }
            }));

        helium.ajax_calls.push(
            helium.planner_api.get_courses(function (data) {
                if (helium.data_has_err_msg(data)) {
                    helium.ajax_error_occurred = true;
                    $("#loading-grades").spin(false);

                    bootbox.alert(helium.get_error_msg(data));
                } else {
                    $.each(data, function (i, course) {
                        helium.grades.courses[course.id] = course
                    });

                    $.when.apply($, helium.ajax_calls).done(function () {
                        if (!helium.ajax_error_occurred) {
                            $($("#course-group-tabs li a").first()).tab("show");

                            /*******************************************
                             * Initialize component libraries
                             ******************************************/
                            $('.easy-pie-chart.percentage').each(function () {
                                const $box = $(this).closest(".infobox"),
                                    barColor = $(this).data("color") || (!$box.hasClass("infobox-dark") ? $box.css(
                                                                                                            "color")
                                                                                                        : "rgba(255,255,255,0.95)"),
                                    trackColor = barColor === "rgba(255,255,255,0.95)" ? "rgba(255,255,255,0.25)"
                                                                                       : "#E2E2E2",
                                    size = parseInt($(this).data("size")) || 50;
                                $(this).easyPieChart({
                                                         barColor: barColor,
                                                         trackColor: trackColor,
                                                         scaleColor: false,
                                                         lineCap: "butt",
                                                         lineWidth: parseInt(size / 10),
                                                         animate: /msie\s*(8|7|6)/.test(
                                                             navigator.userAgent.toLowerCase()) ? false
                                                                                                : 1000,
                                                         size: size
                                                     });
                            });

                            $(".sparkline").each(function () {
                                const $box = $(this).closest(".infobox"),
                                    barColor = !$box.hasClass("infobox-dark") ? $box.css("color") : "#FFF";
                                $(this).sparkline("html", {
                                    tagValuesAttribute: "data-values",
                                    type: "bar",
                                    barColor: barColor,
                                    chartRangeMin: $(this).data("min") || 0
                                });
                            });

                            helium.planner_api.get_grades(function (data) {
                                if (helium.data_has_err_msg(data)) {
                                    helium.ajax_error_occurred = true;
                                    $("#loading-grades").spin(false);

                                    bootbox.alert(helium.get_error_msg(data));
                                } else {
                                    $.each(data.course_groups, function (i, course_group) {
                                        helium.grades.course_groups[course_group.id].course_group_id = course_group.id;
                                        helium.grades.course_groups[course_group.id].grade_points =
                                            course_group.grade_points;
                                        helium.grades.course_groups[course_group.id].overall_grade =
                                            course_group.overall_grade;
                                        helium.grades.course_groups[course_group.id].title = "Overall Grade";
                                        helium.grades.course_groups[course_group.id].color = "#000";

                                        $.each(course_group['courses'], function (i, course) {
                                            helium.grades.courses[course.id].course_group_id = course_group.id;
                                            helium.grades.courses[course.id].grade_points = course.grade_points;
                                            helium.grades.courses[course.id].overall_grade = course.overall_grade;
                                            helium.grades.courses[course.id].type = "course";

                                            $.each(course['categories'], function (index, category) {
                                                helium.grades.categories[category.id] = category;
                                                helium.grades.categories[category.id].course_group_id = course_group.id;
                                                helium.grades.categories[category.id].course = course.id;
                                                helium.grades.categories[category.id].type = "category";
                                            });
                                        });
                                    });

                                    $("div[id^='course-group-container-']").each(function () {
                                        let id = parseInt(
                                                $(this).attr("id").split("course-group-container-")[1].split("_")[0]),
                                            course_div, course_body_div, grade_distribution_string,
                                            pie_grade_by_weight_div, category_table, category_table_body,
                                            pie_weight_data, pie_grade_by_weight_data, course_list,
                                            pie_weight_details = {
                                                series: {
                                                    pie: {
                                                        show: true,
                                                        innerRadius: 0.2,
                                                        highlight: {
                                                            opacity: 0.2
                                                        },
                                                        stroke: {
                                                            color: "#fff",
                                                            width: 2
                                                        },
                                                        label: {
                                                            show: true,
                                                            formatter: function (label, series) {
                                                                return '<div style="font-size:8pt;text-align:center;padding:2px;">'
                                                                       + Math.round(series.percent) + '%</div>';
                                                            }
                                                        }
                                                    }
                                                },
                                                legend: {
                                                    show: false
                                                },
                                                grid: {
                                                    hoverable: true
                                                }
                                            }, default_time_series_items = [helium.grades.course_groups[id]];
                                        helium.grades.series_legend[id] = {};
                                        helium.grades.series_legend[id]["course_group-" + id] = true;

                                        course_list = $("#course-group-piechart-" + id);
                                        course_list.append("<div class=\"space-24\"></div>");

                                        $.each(helium.grades.courses, function (i, course) {
                                            if (course.course_group !== id) {
                                                return true;
                                            }

                                            default_time_series_items.push(course);
                                            helium.grades.series_legend[id]["course-" + course.id] = true;

                                            course_div =
                                                course_list.append("<div id=\"course-body-" + course.id
                                                                   + "\" class=\"widget-box\"><div class=\"widget-header widget-header-flat widget-header-small\"><h6><i class=\"icon-book\"></i> <span>"
                                                                   + course.title
                                                                   + " <span class=\"color-dot inline\" style=\"background-color: "
                                                                   + course.color + "\"></span>"
                                                                   + "</span></h6><a class=\"cursor-hover\" data-action=\"collapse\"><div class=\"widget-toolbar\"><span class=\"badge\" style=\"background-color: "
                                                                   + helium.USER_PREFS.settings.grade_color
                                                                   + " !important\">"
                                                                   + (parseFloat(course.overall_grade.toFixed(2))
                                                                      !== -1
                                                                      ? Math.round(
                                                        course.overall_grade * 100) / 100 + "%" : "N/A")
                                                                   + helium.grades.get_trend_arrow(
                                                        course.trend)
                                                                   + "</span> <i class=\"icon-chevron-up\"></i></div></a></div></div>");

                                            // Build the course grading details div for this course
                                            category_table =
                                                $("<table class=\"table table-striped table-bordered table-hover\"><thead><tr><th>Category</th><th class=\"hidden-xs\">Grades Recorded</th><th>Average Grade</th></tr></thead><tbody id=\"category-table-course-"
                                                  + course.id + "\"></tbody></table>");
                                            category_table_body =
                                                category_table.find("#category-table-course-" + course.id);

                                            pie_weight_data = [];
                                            pie_grade_by_weight_data = [];
                                            let num_categories = 0;
                                            $.each(helium.grades.categories, function (i, category) {
                                                if (category.course !== course.id) {
                                                    return true;
                                                }

                                                num_categories += 1;

                                                pie_weight_data.push(
                                                    {
                                                        label: category.title,
                                                        data: category.weight,
                                                        color: category.color
                                                    });
                                                if (parseFloat(category.grade_by_weight) !== 0) {
                                                    pie_grade_by_weight_data.push(
                                                        {
                                                            label: category.title,
                                                            data: category.grade_by_weight,
                                                            color: category.color
                                                        });
                                                }

                                                category_table_body.append(
                                                    "<tr><td><span class=\"label label-sm\" style=\"background-color: "
                                                    + category.color
                                                    + " !important\">" + category.title
                                                    + "</span></td><td class=\"hidden-xs\">"
                                                    + category.num_homework_graded + " of "
                                                    + category.num_homework
                                                    + "</td><td>" + ((parseFloat(category.weight)
                                                                      !== 0
                                                                      || !course.has_weighted_grading)
                                                                     ? (parseFloat(
                                                            category.overall_grade.toFixed(2)) !== -1
                                                                        ? "<span class=\"badge\" style=\"background-color: "
                                                    + helium.USER_PREFS.settings.grade_color + " !important\">"
                                                    + Math.round(category.overall_grade * 100) / 100 + "%"
                                                    + helium.grades.get_trend_arrow(
                                                                category.trend) + "</span>" : "N/A") : "Not Graded")
                                                    + "</td></tr>");
                                            });

                                            if (num_categories > 0) {
                                                grade_distribution_string =
                                                    course.has_weighted_grading
                                                    ? ("<div class=\"col-xs-12 col-md-3\"><div class=\"row\"><h5 class='align-center'>Weight Distribution</h5><hr /></div><div id=\"course-weight-piechart-"
                                                       + course.id
                                                       + "\"></div></div><div class=\"col-xs-12 col-md-3\"><div class=\"row\"><h5 class='align-center'>Current Grade Distribution</h5><hr /></div><div id=\"course-grade-by-weight-piechart-"
                                                       + course.id + "\"></div></div>") : "";
                                                course_body_div =
                                                    course_div.find("#course-body-" + course.id).append(
                                                        "<div class=\"widget-body\"><div class=\"widget-main\">"
                                                        + grade_distribution_string
                                                        + "<div class=\"row\"><div class=\"col-xs-12 col-md-"
                                                        + (course.has_weighted_grading
                                                           ? "6" : "12") + "\">" + $(
                                                            "<div />").append(category_table.clone()).html()
                                                        + "</div><div class=\"col-xs-12 col-sm-4\"></div></div></div></div></div>");
                                                let pie_weight_div = course_body_div.find(
                                                    "#course-weight-piechart-" + course.id);
                                                pie_grade_by_weight_div =
                                                    course_body_div.find(
                                                        "#course-grade-by-weight-piechart-" + course.id);

                                                if (course.has_weighted_grading) {
                                                    pie_weight_div.css(
                                                        {"width": "90%", "height": "100%", "min-height": "200px"});
                                                    pie_grade_by_weight_div.css(
                                                        {"width": "90%", "height": "100%", "min-height": "200px"});

                                                    $.plot(pie_weight_div, pie_weight_data, pie_weight_details);
                                                    $.plot(pie_grade_by_weight_div, pie_grade_by_weight_data,
                                                           pie_weight_details);

                                                    pie_weight_div.bind("plothover", helium.grades.pie_hover);
                                                    pie_grade_by_weight_div.bind("plothover",
                                                                                 helium.grades.pie_hover);
                                                }
                                            } else {
                                                course_div.find("#course-body-" + course.id).append(
                                                    "<div class=\"widget-body\"><div class=\"widget-main\"><div class=\"row\"><div class=\"col-xs-12 col-sm-10 col-sm-offset-1 well\">This class does not have any categories. Head over to <a href=\"/planner/classes\">the Classes page</a> to add them.</div></div></div></div>");
                                            }
                                        });

                                        helium.grades.populate_time_series(id, default_time_series_items);
                                    });

                                    $("#loading-grades").spin(false);

                                    if ($("#course-group-tabs a").length === 0) {
                                        $("#no-grades-tab").addClass("active");
                                    }
                                }
                            });
                        }
                    });
                }
            }));
    });
});
