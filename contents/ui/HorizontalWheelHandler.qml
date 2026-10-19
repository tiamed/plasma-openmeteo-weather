import QtQuick
import org.kde.kirigami as Kirigami

WheelHandler {
    id: handler

    required property Flickable flickable
    property real snapStep: 0
    property int notchSteps: 1
    property real pendingAngle: 0

    readonly property NumberAnimation scrollAnimation: NumberAnimation {
        target: handler.flickable
        property: "contentX"
        duration: Kirigami.Units.shortDuration
        easing.type: Easing.OutCubic
    }

    readonly property Timer settleTimer: Timer {
        interval: 160
        onTriggered: handler.animateTo(handler.snapX(handler.flickable.contentX))
    }

    readonly property Connections flickConnections: Connections {
        target: handler.flickable

        function onMovementStarted() {
            handler.scrollAnimation.stop();
            handler.settleTimer.stop();
        }

        function onMovementEnded() {
            handler.animateTo(handler.snapX(handler.flickable.contentX));
        }
    }

    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

    function maxX() {
        return Math.max(0, flickable.contentWidth - flickable.width);
    }

    function clampX(x) {
        return Math.max(0, Math.min(maxX(), x));
    }

    function snapX(x) {
        const limit = maxX();
        if (snapStep <= 0)
            return clampX(x);
        const snapped = Math.round(x / snapStep) * snapStep;
        // The last card rarely ends on a step boundary, so treat the end as a snap point too.
        if (limit - x < Math.abs(snapped - x))
            return limit;
        return clampX(snapped);
    }

    function animateTo(x) {
        if (Math.abs(x - flickable.contentX) < 1) {
            scrollAnimation.stop();
            return;
        }
        scrollAnimation.stop();
        scrollAnimation.from = flickable.contentX;
        scrollAnimation.to = x;
        scrollAnimation.start();
    }

    function scrollByPixels(delta) {
        const nextX = clampX(flickable.contentX - delta);
        if (nextX === flickable.contentX)
            return false;
        scrollAnimation.stop();
        flickable.cancelFlick();
        flickable.contentX = nextX;
        settleTimer.restart();
        return true;
    }

    function scrollByAngle(angle) {
        if (pendingAngle !== 0 && Math.sign(pendingAngle) !== Math.sign(angle))
            pendingAngle = 0;
        pendingAngle += angle;
        const steps = Math.trunc(pendingAngle / 120);
        const base = scrollAnimation.running ? scrollAnimation.to : flickable.contentX;
        if (steps === 0)
            return (angle > 0 && base > 0) || (angle < 0 && base < maxX());
        pendingAngle -= steps * 120;
        const step = snapStep > 0 ? snapStep : 120;
        const target = snapX(base - steps * notchSteps * step);
        if (target === base)
            return false;
        flickable.cancelFlick();
        animateTo(target);
        return true;
    }

    function scrollHorizontally(pixelDelta, angleDelta) {
        return pixelDelta !== 0 ? scrollByPixels(pixelDelta) : scrollByAngle(angleDelta);
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
        const px = event.pixelDelta.x;
        const py = event.pixelDelta.y;
        const ax = event.angleDelta.x;
        const ay = event.angleDelta.y;
        const dx = px !== 0 ? px : ax;
        const dy = py !== 0 ? py : ay;
        const isShift = (event.modifiers & Qt.ShiftModifier) !== 0;

        if (isShift && dy !== 0) {
            event.accepted = scrollHorizontally(py, ay);
            return;
        }
        // Touchpad vertical swipes carry small horizontal jitter, so pick the dominant axis.
        if (Math.abs(dx) > Math.abs(dy)) {
            event.accepted = scrollHorizontally(px, ax);
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
