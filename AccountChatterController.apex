public with sharing class AccountChatterController {

    public class FeedItemWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String body;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public String createdByName;
        @AuraEnabled public List<CommentWrapper> comments = new List<CommentWrapper>();

        @AuraEnabled public String newComment; // user input
    }

    public class CommentWrapper {
        @AuraEnabled public String commentBody;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public String createdByName;

        @AuraEnabled public String replyText; // user input
    }

    @AuraEnabled
    public static List<FeedItemWrapper> getRecordFeeds(Id recordId) {
        List<FeedItemWrapper> wrappedFeedItems = new List<FeedItemWrapper>();
         if (recordId == null) return wrappedFeedItems;
        // Resolve related Account Id
        Id accountId = resolveAccountId(recordId);
        if (accountId == null) return wrappedFeedItems;
        
        List<AccountFeed> feeds = [
            SELECT Id, Body, CreatedDate, CreatedBy.Name,
                   (SELECT CommentBody, CreatedDate, CreatedBy.Name FROM FeedComments ORDER BY CreatedDate)
            FROM AccountFeed
            WHERE ParentId = :accountId AND Type = 'TextPost'
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];

        for (AccountFeed feed : feeds) {
            FeedItemWrapper wrap = new FeedItemWrapper();
            wrap.id = feed.Id;
            wrap.body = stripHtmlTags(feed.Body);
            wrap.createdDate = feed.CreatedDate;
            wrap.createdByName = feed.CreatedBy.Name;

            for (FeedComment fc : feed.FeedComments) {
                CommentWrapper comment = new CommentWrapper();
                comment.commentBody = stripHtmlTags(fc.CommentBody);
                comment.createdDate = fc.CreatedDate;
                comment.createdByName = fc.CreatedBy.Name;
                wrap.comments.add(comment);
            }

            wrappedFeedItems.add(wrap);
        }

        return wrappedFeedItems;
    }

    @AuraEnabled
    public static void addCommentToFeed(Id feedItemId, String commentBody) {
        if (String.isBlank(feedItemId) || String.isBlank(commentBody)) return;
        
        FeedComment fc = new FeedComment();
        fc.FeedItemId = feedItemId;
        fc.CommentBody = commentBody;
        insert fc;
    }

    @AuraEnabled
    public static void createFeedItem(Id recordId, String body) {
        if (String.isBlank(recordId) || String.isBlank(body)) return;
        Id accountId = resolveAccountId(recordId);
        if (accountId == null) return;
        
        FeedItem post = new FeedItem();
        post.ParentId = accountId;
        post.Body = body;
        post.Type = 'TextPost'; // Required for text-based feed posts
        insert post;
    }

    private static String stripHtmlTags(String input) {
        if (String.isNotBlank(input)) {
            return input.replaceAll('<[^>]+>', '');
        }
        return input;
    }
    private static Id resolveAccountId(Id recordId) {
        String objName = recordId.getSObjectType().getDescribe().getName();
        switch on objName {
            when 'Account'     { return recordId; }
            when 'Opportunity' { return [SELECT AccountId FROM Opportunity WHERE Id = :recordId LIMIT 1].AccountId; }
            when 'Case'        { return [SELECT AccountId FROM Case WHERE Id = :recordId LIMIT 1].AccountId; }
            when else          { return null; }
        }
    }
}
