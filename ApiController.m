// Parse backend API controller with ReactiveCocoa

- (RACSignal*)getObjectsForClassName:(NSString*)className withPredicate:(NSPredicate*)predicate includeKeys:(NSArray *)keys {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        DDLogDebug(@"Fetching objects for: %@", className);
        PFQuery *query = [PFQuery queryWithClassName:className predicate:predicate];
        
        if (keys) {
            for (NSString *includeKey in keys) {
                [query includeKey:includeKey];
            }
        }

        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                DDLogVerbose(@"Successfully retrieved %ld %@ objects.", (long)objects.count, className);
                [subscriber sendNext:objects];
                [subscriber sendCompleted];
            } else {
                [subscriber sendError:error];
            }
        }];
        
        return [RACDisposable disposableWithBlock:^{
            [query cancel];
        }];
    }];
}

- (RACSignal *)fetchImagesForEvents:(NSArray *)events {
    return [RACSignal concat:[events.rac_sequence map:^(EventModel *event) {
        return [[self fetchImagesForEvent:event] map:^id(id value) {
            event.images = [ImageModel modelsWithObjects:value];
            return [RACSignal return:events];
        }];
    }]];
}

- (RACSignal *)fetchTimeTableForEvents:(NSArray *)events {
    return [RACSignal concat:[events.rac_sequence map:^(EventModel *event) {
        return [[self fetchTimeTableForEvent:event] map:^id(id value) {
            event.timetable = [TimeTableModel modelsWithObjects:value];
            return [RACSignal return:events];
        }];
    }]];
}

- (RACSignal *)fetchImagesForEvent:(EventModel *)event {
    PFRelation *imagesRelation = event.pfObject[@"images"];
    return [self fetchRelationObjectsForRelation:imagesRelation withPredicate:nil includeKeys:nil];
}

- (RACSignal *)fetchRelationObjectsForRelation:(PFRelation*)relation withPredicate:(NSPredicate *)predicate includeKeys:(NSArray *)keys{
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        DDLogDebug(@"Fetching relations objects for: %@", relation.description);
        PFQuery *query = [relation query];
        if (keys) {
            for (NSString *includeKey in keys) {
                [query includeKey:includeKey];
            }
        }
        [query findObjectsInBackgroundWithBlock:^(NSArray *results, NSError *error) {
            if (!error) {
                DDLogVerbose(@"Successfully retrieved %ld %@ relation objects.", (long)results.count, relation.description);
                [subscriber sendNext:results];
                [subscriber sendCompleted];
            } else {
                [subscriber sendError:error];
            }
        }];
        
        return [RACDisposable disposableWithBlock:^{
            [query cancel];
        }];
    }];

}