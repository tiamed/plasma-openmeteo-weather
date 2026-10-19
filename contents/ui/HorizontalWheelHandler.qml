import QtQuick

WheelHandler {
    id: handler

    required property Flickable flickable

    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

    function wheelDelta(pixel, angle) {
        return pixel !== 0 ? pixel : angle;
    }

    function verticalAncestor() {
        let item = flickable.parent;
        while (item) {
            if (item instanceof Flickable && item.flickableDirection !== Flickable.HorizontalFlick)
                return item;
            item = item.parent;
        }
        return null;
    }

    function scrollX(delta) {
        const maxX = Math.max(0, flickable.contentWidth - flickable.width);
        const nextX = Math.max(0, Math.min(maxX, flickable.contentX - delta));
        if (nextX === flickable.contentX)
            return false;
        flickable.cancelFlick();
        flickable.contentX = nextX;
        return true;
    }

    function scrollY(target, delta) {
        const maxY = Math.max(0, target.contentHeight - target.height);
        const nextY = Math.max(0, Math.min(maxY, target.contentY - delta));
        if (nextY === target.contentY)
            return false;
        target.cancelFlick();
        target.contentY = nextY;
        return true;
    }

    onWheel: event => {
        const dx = wheelDelta(event.pixelDelta.x, event.angleDelta.x);
        const dy = wheelDelta(event.pixelDelta.y, event.angleDelta.y);
        const isShift = (event.modifiers & Qt.ShiftModifier) !== 0;

        if (isShift && dy !== 0) {
            event.accepted = scrollX(dy);
            return;
        }
        // Touchpad vertical swipes carry small horizontal jitter, so pick the dominant axis.
        if (Math.abs(dx) > Math.abs(dy)) {
            event.accepted = scrollX(dx);
            return;
        }
        const outer = verticalAncestor();
        if (outer && dy !== 0) {
            scrollY(outer, dy);
            event.accepted = true;
        } else {
            event.accepted = false;
        }
    }
}
