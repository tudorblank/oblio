// SPDX-License-Identifier: GPL-3.0-or-later
// Settings > a shell part with options (services/Parts.qml): its options, one row each.
import QtQuick
import qs.services

Column {
    id: page

    required property string part
    readonly property var info: Parts.part(part)

    spacing: 22

    SettingGroup {
        title: page.info ? page.info.name.toUpperCase() : ""
        Repeater {
            model: page.info?.options ?? []
            OptionRow {
                required property var modelData
                option: modelData
                value: Parts.option(page.part, modelData.key)
                onPicked: v => Parts.set(page.part, modelData.key, v)
            }
        }
    }
}
