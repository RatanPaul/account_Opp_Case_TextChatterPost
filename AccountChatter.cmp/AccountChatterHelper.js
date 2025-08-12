({
    loadFeedItems: function (component) {
        component.set("v.isLoading", true);

        var action = component.get("c.getRecordFeeds");
        action.setParams({ recordId: component.get("v.recordId") });

        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                let feedItems = response.getReturnValue();
                // Clear any previous comment inputs
                feedItems.forEach(item => item.newComment = '');
                component.set("v.feedItems", feedItems);
            } else {
                console.error('Failed to load feed items: ', response.getError());
            }
            component.set("v.isLoading", false);
        });

        $A.enqueueAction(action);
    }
});