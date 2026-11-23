// SPDX-License-Identifier: GPL-3.0-or-later
// A GTK 3 module (GTK3_MODULES=oblio-gtk) for what a stylesheet can't reach. Loaded into every
// GTK 3 app, it only touches the widgets named here.
#include <gtk/gtk.h>

// Thunar's sidebar indents its entries with an empty text cell (12 px plus spacing)
static void thunar_sidebar(GtkWidget *view) {
    GtkTreeViewColumn *col = gtk_tree_view_get_column(GTK_TREE_VIEW(view), 0);
    if (!col) return;
    GList *cells = gtk_cell_layout_get_cells(GTK_CELL_LAYOUT(col));
    GtkCellRenderer *spacer = g_list_nth_data(cells, 1);
    if (GTK_IS_CELL_RENDERER_TEXT(spacer)) {
        gtk_cell_layout_clear_attributes(GTK_CELL_LAYOUT(col), spacer);
        gtk_cell_renderer_set_visible(spacer, FALSE);
        gtk_tree_view_column_queue_resize(col);
    }
    g_list_free(cells);
}

static gboolean on_realize(GSignalInvocationHint *hint, guint n, const GValue *values, gpointer data) {
    GtkWidget *w = g_value_get_object(&values[0]);
    if (GTK_IS_TREE_VIEW(w) && g_strcmp0(G_OBJECT_TYPE_NAME(w), "ThunarShortcutsView") == 0)
        thunar_sidebar(w);
    return TRUE;
}

G_MODULE_EXPORT void gtk_module_init(gint *argc, gchar ***argv) {
    // the widget class has to exist before its signals can be looked up
    g_type_class_ref(GTK_TYPE_WIDGET);
    g_signal_add_emission_hook(g_signal_lookup("realize", GTK_TYPE_WIDGET), 0, on_realize, NULL, NULL);
}
