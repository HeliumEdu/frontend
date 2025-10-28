/**
 * Copyright (c) 2025 Helium Edu
 *
 * JavaScript functionality for persistence and the HeliumMaterials object on the /planner/materials page.
 *
 * Be aware that this is legacy code, and we would love to have the capacity to completely rewrite it.
 * The way JavaScript and Ajax are being used is pretty dated. Are you a frontend expert in search of an open source
 * project and interested in joining forces? Reach out and let us know! contact@alexlaird.com
 *
 * @license MIT
 * @version 1.15.11
 */

/**
 * Create the HeliumMaterials persistence object.
 *
 * @constructor construct the HeliumMaterials persistence object
 */
function HeliumMaterials() {
    "use strict";

    helium.MATERIAL_STATUS_CHOICES = [
        "Owned",
        "Rented",
        "Ordered",
        "Shipped",
        "Need",
        "Received",
        "To Sell",
        "Digital"
    ];

    this.material_group_table = {};
    this.edit = false;
    this.edit_id = -1;
    this.courses = {};

    let self = this;

    /*******************************************
     * Functions
     ******************************************/

    /**
     * Revert persistence for adding/editing a MaterialGroup.
     */
    this.nullify_material_group_persistence = function () {
        self.edit = false;
        self.edit_id = -1;
        helium.ajax_error_occurred = false;
    };

    /**
     * Revert persistence for adding/editing a Material.
     */
    this.nullify_material_persistence = function () {
        self.edit = false;
        self.edit_id = -1;
        helium.ajax_error_occurred = false;
    };

    /**
     * Clear Material marked in the Material modal.
     */
    this.clear_material_errors = function () {
        helium.ajax_error_occurred = false;
        $("#material-title").parent().parent().removeClass("has-error");
    };

    /**
     * Clear MaterialGroup marked in the MaterialGroup modal.
     */
    this.clear_material_group_errors = function () {
        helium.ajax_error_occurred = false;
        $("#material-group-title").parent().parent().removeClass("has-error");
    };

    /**
     * Create a new material in the currently open material group.
     */
    this.create_material_for_group_btn = function () {
        self.edit = false;

        $("#delete-material").hide();

        // First, ensure we have a material group to add the new material to
        $("#material-modal-label").html("Add Material");
        $("#material-title").val("");
        $("#material-courses").val("");
        $("#material-courses").trigger("chosen:updated");
        $("#material-courses").trigger("change");

        $("#material-group").val(
            $("#material-group-tabs li.active a").attr("href") ? $("#material-group-tabs li.active a").attr("href")
                .split("material-group-")[1] : "");

        $("#material-status").val("0");
        $("#material-condition").val("0");
        $("#material-website").val("");
        $("#material-price").val("");
        $("#material-details").html("");

        $("#loading-material-modal").spin(false);
        $("#material-modal").modal("show");
    };

    /**
     * Add the given material group's data to the page.
     *
     * @param data the data for the material group to be added
     */
    this.add_material_group_to_page = function (data) {
        helium.ajax_error_occurred = false;

        if (helium.data_has_err_msg(data)) {
            helium.ajax_error_occurred = true;
            $("#loading-material-group-modal").spin(false);

            $("#material-group-error").html(helium.get_error_msg(data));
            $("#material-group-error").parent().show("fast");
        } else {
            let input_tab, material_group_div, div, table_div;
            $.each($('a[href^="#material-group-"]'), function (index, tab) {
                if (!input_tab && data.title < $.trim($(tab).text())) {
                    input_tab = tab;
                }
            });
            if (input_tab) {
                input_tab = $(input_tab).parent();
            } else {
                input_tab = $("#create-material-group-li");
            }
            input_tab.before("<li><a data-toggle=\"tab\" href=\"#material-group-" + data.id
                             + "\"><i class=\"icon-list r-110\"></i> <span class=\"hidden-xs\">" + data.title
                             + (!data.shown_on_calendar
                                ? "</span> <i class=\"icon-eye-close\"></i>" : "</span>")
                             + "</a></li>");
            material_group_div =
                "<div id=\"material-group-" + data.id
                + "\" class=\"tab-pane\"><div class=\"row\"><div class=\"col-xs-12\"><div class=\"table-header\"><span id=\"material-group-title-"
                + data.id + "\">" + data.title + (!data.shown_on_calendar ? " <i class=\"icon-eye-close\"></i>" : "")
                + "</span></span><label class=\"pull-right inline action-buttons\" style=\"padding-right: 10px\"><a class=\"cursor-hover\" id=\"create-material-for-group-"
                + data.id
                + "\"><span class=\"white\"><i class=\"icon-plus-sign-alt bigger-120 hidden-print\"></i></span></a>&nbsp;<a class=\"cursor-hover\" id=\"edit-material-group-"
                + data.id
                + "\"><span class=\"white\"><i class=\"icon-edit bigger-120 hidden-print\"></i></span>&nbsp;</a><a class=\"cursor-hover\" id=\"delete-material-group-"
                + data.id
                + "\"><span class=\"white\"><i class=\"icon-trash bigger-120 hidden-print\"></i></span></a></label></div><div class=\"table-responsive\"><table id=\"material-group-table-"
                + data.id
                + "\" class=\"table table-striped table-bordered table-hover\"><thead><tr><th>Title</th><th class=\"hidden-xs\">Price</th><th class=\"hidden-xs\">Status</th><th>Classes</th><th>Details</th></tr></thead><tbody id=\"material-group-table-body-"
                + data.id + "\"></tbody></table></div></div></div></div>";
            // Determine the placement for this tab
            div = $("#material-group-tab-content").append(material_group_div);
            // Bind clickable attributes to their respective handlers
            div.find("#create-material-for-group-" + data.id).on("click", function () {
                self.create_material_for_group_btn();
            });
            div.find("#edit-material-group-" + data.id).on("click", function () {
                self.edit_material_group_btn($(this));
            });
            div.find("#delete-material-group-" + data.id).on("click", function () {
                self.delete_material_group_btn($(this));
            });

            table_div = div.find("#material-group-table-" + data.id).dataTable(
                {
                    lengthMenu: [
                        [5, 10, 25, 50, -1],
                        [5, 10, 25, 50, "All"]
                    ],
                    pageLength: 10,
                    aoColumns: [
                        null,
                        {sClass: "hidden-xs"},
                        {sClass: "hidden-xs"},
                        null,
                        null
                    ],
                    oLanguage: {
                        sEmptyTable: "Nothing to see here. Click \"+\" to add a material.",
                        sInfo: "Showing _START_ to _END_ of _TOTAL_ materials",
                        sInfoEmpty: "Showing 0 to 0 of 0 materials",
                        sLengthMenu: "Show _MENU_ materials",
                        oPaginate: {
                            sPrevious: "<i class=\"icon-angle-left\"></i>",
                            sNext: "<i class=\"icon-angle-right\"></i>"
                        }
                    }
                });
            self.material_group_table[data.id] = table_div.DataTable();
            table_div.parent().find("#material-group-table-" + data.id + "_length").parent()
                .addClass("col-xs-12").removeClass("col-xs-6")
                .next().remove();
            table_div.parent().find("#material-group-table-" + data.id + "_length").parent().parent()
                .addClass("hidden-print");
            table_div.parent().find("#material-group-table-" + data.id + "_length select").attr("style", "display: inline");
            table_div.parent().find("#material-group-table-" + data.id + "_info").parent().parent()
                .addClass("hidden-print");

            self.nullify_material_group_persistence();

            $("#loading-material-group-modal").spin(false);
            $("#material-group-modal").modal("hide");

            $("#material-group-tabs li a[href='#material-group-" + data.id + "']").tab("show");
        }
    };

    /**
     * Show the Material Group modal to edit a material group.
     *
     * @param selector the selector for the edit button of a material group
     */
    this.edit_material_group_btn = function (selector) {
        helium.ajax_error_occurred = false;

        if (!self.edit) {
            $("#loading-materials").spin(helium.SMALL_LOADING_OPTS);

            self.edit = true;

            $("#material-group-modal-label").html("Edit Group");
            // Initialize dialog attributes for editing
            self.edit_id = selector.attr("id").split("edit-material-group-")[1];
            helium.planner_api.get_material_group(function (data) {
                if (helium.data_has_err_msg(data)) {
                    helium.ajax_error_occurred = true;
                    $("#loading-materials").spin(false);
                    self.edit = false;
                    self.edit_id = -1;

                    bootbox.alert(helium.get_error_msg(data));
                } else {
                    const material_group = data;
                    $("#material-group-title").val(material_group.title);
                    $("#material-group-shown-on-calendar").prop("checked", !material_group.shown_on_calendar);

                    $("#loading-material-group-modal").spin(false);
                    $("#loading-materials").spin(false);
                    $("#material-group-modal").modal("show");
                }
            }, self.edit_id);
        }
    };

    /**
     * Delete the given material group.
     *
     * @param selector the selector for the edit button of a material group
     */
    this.delete_material_group_btn = function (selector) {
        helium.ajax_error_occurred = false;

        const id = selector.attr("id").split("delete-material-group-")[1];
        bootbox.dialog(
            {
                message: "Are you sure you want to delete this group? Doing so will also delete all materials associated with it. This action cannot be undone.",
                onEscape: true,
                buttons: {
                    "delete": {
                        "label": '<i class="icon-trash"></i> Delete',
                        "className": "btn-sm btn-danger",
                        "callback": function () {
                            $("#loading-materials").spin(helium.SMALL_LOADING_OPTS);
                            helium.planner_api.delete_material_group(function (data) {
                                if (helium.data_has_err_msg(data)) {
                                    helium.ajax_error_occurred = true;
                                    $("#loading-materials").spin(false);

                                    bootbox.alert(helium.get_error_msg(data));
                                } else {
                                    $("#material-group-" + id).slideUp("fast", function () {
                                        const parent = $('a[href="#material-group-' + id + '"]').parent();
                                        if (parent.prev().length > 0) {
                                            parent.prev().find("a").tab("show");
                                        } else if (parent.next().length > 0 && !parent.next()
                                            .is($("#create-material-group-li"))) {
                                            parent.next().find("a").tab("show");
                                        } else {
                                            $("#no-materials-tab").addClass("active");
                                        }

                                        $(this).remove();
                                        $('a[href="#material-group-' + id + '"]').parent().remove();
                                        $("#loading-materials").spin(false);
                                    });
                                }
                            }, id);
                        }
                    },
                    "cancel": {
                        "label": '<i class="icon-remove"></i> Cancel',
                        "className": "btn-sm"
                    }
                }
            });
    };

    /**
     * Show the Material modal to edit a material.
     *
     * @param selector the selector for the row of a material
     */
    this.edit_material_btn = function (selector) {
        helium.ajax_error_occurred = false;

        if (!self.edit) {
            $("#loading-materials").spin(helium.SMALL_LOADING_OPTS);

            $("#delete-material").show();
            self.edit = true;

            $("#material-modal-label").html("Edit Material");

            // Initialize dialog attributes for editing
            self.edit_id = parseInt(selector.attr("id").split("material-")[1]);
            self.material_group_id =
                parseInt(selector.closest("[id^='material-group-table-']").attr('id')
                             .split('material-group-table-body-')[1]);
            helium.planner_api.get_material(function (data) {
                if (helium.data_has_err_msg(data)) {
                    helium.ajax_error_occurred = true;
                    $("#loading-materials").spin(false);
                    self.edit = false;
                    self.edit_id = -1;

                    bootbox.alert(helium.get_error_msg(data));
                } else {
                    const material = data;

                    // Change display to the correct material group tab
                    $('a[href="#material-group-' + material.material_group + '"]').tab("show");

                    $("#material-title").val(material.title);

                    $("#material-group").val(material.material_group);
                    $("#material-courses").val(material.courses);
                    $("#material-courses").trigger("chosen:updated");
                    $("#material-courses").trigger("change");
                    $("#material-status").val(material.status);
                    $("#material-status").trigger("chosen:updated");
                    $("#material-status").trigger("change");
                    $("#material-condition").val(material.condition);
                    $("#material-condition").trigger("chosen:updated");
                    $("#material-condition").trigger("change");
                    $("#material-website").val(material.website);
                    $("#" + $(".open-website button").attr("for")).trigger("focusout");
                    $("#material-price").val(material.price);
                    $("#material-details").html(material.details);

                    $("#loading-material-modal").spin(false);
                    $("#loading-materials").spin(false);
                    $("#material-modal").modal("show");
                }
            }, self.material_group_id, self.edit_id);
        }
    };

    /**
     * Delete the given material.
     *
     * @param selector the selector for the row of a material
     */
    this.delete_material_btn = function (selector) {
        helium.ajax_error_occurred = false;

        $("#material-modal").modal("hide");

        const id = selector.attr("id").split("material-")[1];
        const material_group_id = parseInt(
            selector.closest("[id^='material-group-table-']").attr('id').split('material-group-table-body-')[1]);
        bootbox.dialog(
            {
                message: "Are you sure you want to delete this material?",
                onEscape: true,
                buttons: {
                    "delete": {
                        "label": '<i class="icon-trash"></i> Delete',
                        "className": "btn-sm btn-danger",
                        "callback": function () {
                            $("#loading-materials").spin(helium.SMALL_LOADING_OPTS);
                            helium.ajax_calls.push(helium.planner_api.delete_material(function (data) {
                                if (helium.data_has_err_msg(data)) {
                                    helium.ajax_error_occurred = true;
                                    $("#loading-materials").spin(false);

                                    bootbox.alert(helium.get_error_msg(data));
                                } else {
                                    $("#material-" + id).slideUp("fast", function () {
                                        self.material_group_table[$("#material-group-tabs li.active a")
                                            .attr("href").split("#material-group-")[1]].row($(this)).remove()
                                            .draw();

                                        $("#loading-materials").spin(false);
                                    });
                                }
                            }, material_group_id, id));
                        }
                    },
                    "cancel": {
                        "label": '<i class="icon-remove"></i> Cancel',
                        "className": "btn-sm"
                    }
                }
            });
    };

    /**
     * Add a material to the given material group.
     *
     * @param material_data the material data with which to build the material
     * @param table the material group table in which to add the material
     */
    this.add_material_to_group = function (material_data, table) {
        const row = table.row.add(
                ["<span class=\"label label-sm title-label\" style=\"background-color: " + helium.USER_PREFS.settings.material_color + " !important\">"
                 + (material_data.website !== "" ? "<a target=\"_blank\" href=\"" + material_data.website
                 + "\" class=\"planner-title-with-link\">" + material_data.title
                 + " <i class=\"icon-external-link\"></i></a>" : material_data.title) + "</span>",
                 material_data.price,
                 helium.MATERIAL_STATUS_CHOICES[material_data.status], self.get_course_names(material_data.courses),
                 helium.get_comments_with_link(material_data.details)]).node(),
            row_div = $(row).attr("id", "material-" + material_data.id);
        // Bind clickable attributes to their respective handlers
        row_div.find("[class$='-with-link']").on("click", function (e) {
            e.stopImmediatePropagation();
        });
        row_div.on("click", function () {
            self.edit_material_btn($(this));
        });
    };

    /**
     * Retrieve the string list of course names for the list of IDs.
     *
     * @param ids of courses
     */
    this.get_course_names = function (ids) {
        let course_names = "", i = 0;

        for (i = 0; i < ids.length; i += 1) {
            const course = self.courses[ids[i]];
            course_names +=
                ("<span class=\"label label-sm title-label\" style=\"background-color: " + course.color
                 + " !important\">" + (course.website !== "" ? "<a target=\"_blank\" href=\"" + course.website
                 + "\" class=\"planner-title-with-link\">" + course.title
                 + " <i class=\"icon-external-link\"></i></a>" : course.title) + "</span> ");
        }

        return course_names;
    };

    /**
     * Resort material groups alphabetically.
     */
    this.resort_material_groups = function () {
        let group_tabs = $('a[href^="#material-group-"]'), swapped = true, i = 1, tab = null, prev_tab = null,
            prev = null;

        // Good 'ol bubble sort the entries
        while (swapped) {
            swapped = false;
            for (i = 1; i < group_tabs.length; i += 1) {
                tab = group_tabs[i];
                prev_tab = group_tabs[i - 1];
                if ($.trim($(tab).text()) < $.trim($(prev_tab).text())) {
                    $(prev_tab).parent().before($(tab).parent());

                    prev = group_tabs[i];
                    group_tabs[i] = group_tabs[i - 1];
                    group_tabs[i - 1] = prev;

                    swapped = true;
                }
            }
        }
    };
}

// Initialize HeliumMaterials and give a reference to the Helium object
helium.materials = new HeliumMaterials();

/*******************************************
 * jQuery initialization
 ******************************************/

$(document).ready(function () {
    "use strict";

    $("#loading-materials").spin(helium.SMALL_LOADING_OPTS);
    $("#loading-material-group-modal").spin(false);
    $("#loading-material-modal").spin(false);

    /*******************************************
     * Initialize component libraries
     ******************************************/
    $.extend($.fn.dataTable.defaults, {
        "searching": false
    });

    if ($(window).width() > 768) {
        $("#material-courses").chosen({width: "100%", search_contains: true, no_results_text: "No classes match"});
    }

    bootbox.setDefaults({
                            locale: 'en'
                        });

    /*******************************************
     * Other page initialization
     ******************************************/
    $(".wysiwyg-editor").ace_wysiwyg({
                                         toolbar: [
                                             {name: "bold",  className:'btn-info'}, {name: "italic",  className:'btn-info'}, {name: "strikethrough",  className:'btn-info'}, {name: "underline",  className:'btn-info'},
                                             null,
                                             {name: "createLink", className:'btn-pink'}, {name: "unlink", className:'btn-pink'},
                                             null,
                                             {name: "insertunorderedlist", className:'btn-success'}, {name: "insertorderedlist", className:'btn-success'},
                                             null,
                                             {name: "indent", className:'btn-purple'}, {name: "outdent", className:'btn-purple'},
                                             null,
                                             "foreColor"
                                         ]
                                     }).prev().addClass("wysiwyg-style3");

    $.when.apply($, helium.ajax_calls).done(function () {
        helium.ajax_calls.push(
            helium.planner_api.get_all_courses_by_user_id(function (data) {
                if (helium.data_has_err_msg(data)) {
                    helium.ajax_error_occurred = true;
                    $("#loading-materials").spin(false);

                    bootbox.alert(helium.get_error_msg(data));
                } else {
                    const courses = Object.entries(data);
                    courses.sort((a, b) => {
                        if (a[1].title < b[1].title) {
                            return -1;
                        } else if (a[1].title > b[1].title) {
                            return 1;
                        }
                        return 0;
                    });

                    $.each(courses, function (index, course_tuple) {
                        let course = course_tuple[1];
                        helium.materials.courses[course.id] = course;
                        $("#material-courses")
                            .append("<option value=\"" + course.id + "\">" + course.title + " <span class=\"color-dot inline\" style=\"background-color: " + course.color + "\"></span></option>");
                    });

                    if (data.length <= 0) {
                        $("#material-courses-form-group").hide("fast");
                    } else {
                        $("#material-courses-form-group").show("fast");
                    }

                    $("#material-courses").prop("disabled", data.length === 0).trigger("chosen:updated");
                    $("#material-courses").trigger("change");
                }
            }, helium.USER_PREFS.id));

        helium.ajax_calls.push(
            helium.planner_api.get_material_groups(function (data) {
                $.each(data, function (i, material_group_data) {
                    helium.materials.add_material_group_to_page(material_group_data);
                });
            }));

        $.when.apply($, helium.ajax_calls).done(function () {
            if (!helium.ajax_error_occurred) {
                $("#material-group-tabs li a[href^='#material-group-']").first().tab("show");

                $("table[id^='material-group-table-']").each(function () {
                    let i = 0, id = $(this).attr("id").split("material-group-table-")[1], table_div = $(this);

                    helium.ajax_calls.push(
                        helium.planner_api.get_materials_by_material_group_id(function (data) {
                            if (helium.data_has_err_msg(data)) {
                                helium.ajax_error_occurred = true;
                                $("#loading-materials").spin(false);

                                bootbox.alert(helium.get_error_msg(data));
                            } else {
                                for (i = 0; i < data.length; i += 1) {
                                    helium.materials.add_material_to_group(data[i],
                                                                           helium.materials.material_group_table[id]);
                                }
                                helium.materials.material_group_table[id].draw();
                            }
                        }, id));
                });
            }
        });

        $.when.apply($, helium.ajax_calls).done(function () {
            if ($("#material-group-tabs a").length === 1) {
                $("#no-materials-tab").addClass("active");
            }

            $("#loading-materials").spin(false);
        });
    });
});
