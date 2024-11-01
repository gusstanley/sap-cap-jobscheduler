using {db} from '../db/schema';

service RootService {

    entity Books as projection on db.Books;

}

annotate RootService.Books with @(restrict: [{
    grant: 'READ',
    to   : 'jobscheduler'
}]);
