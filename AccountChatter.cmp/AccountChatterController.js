({
    doInit: function (component, event, helper) {
        helper.loadFeedItems(component);
    },

    postComment: function (component, event, helper) {
        var feedItemId = event.getSource().get("v.value");
        var feedItems = component.get("v.feedItems");
        var commentBody = "";

        feedItems.forEach(function(item) {
            if (item.id === feedItemId) {
                commentBody = item.newComment;
            }
        });

        if (!commentBody || commentBody.trim() === '') return;

        var action = component.get("c.addCommentToFeed");
        action.setParams({
            feedItemId: feedItemId,
            commentBody: commentBody
        });

        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                component.find("notifLib").showToast({
                    title: "Success",
                    message: "Comment posted.",
                    variant: "success"
                });
                helper.loadFeedItems(component); // Reuse
            }
        });

        $A.enqueueAction(action);
    },

    postFeedItem: function (component, event, helper) {
        var body = component.get("v.newPostBody");
        if (!body || body.trim() === '') return;

        var action = component.get("c.createFeedItem");
        action.setParams({
            recordId: component.get("v.recordId"),
            body: body
        });

        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                component.find("notifLib").showToast({
                    title: "Success",
                    message: "Post created.",
                    variant: "success"
                });
                component.set("v.newPostBody", '');
                helper.loadFeedItems(component); // Reuse
            }
        });

        $A.enqueueAction(action);
    }
});