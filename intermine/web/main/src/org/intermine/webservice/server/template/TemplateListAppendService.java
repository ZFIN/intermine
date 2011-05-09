package org.intermine.webservice.server.template;

import java.util.Arrays;
import java.util.HashMap;

import org.intermine.api.InterMineAPI;
import org.intermine.api.profile.InterMineBag;
import org.intermine.api.profile.Profile;
import org.intermine.api.bag.BagQueryResult;
import org.intermine.api.query.MainHelper;
import org.intermine.objectstore.ObjectStoreException;
import org.intermine.objectstore.query.Query;
import org.intermine.objectstore.query.QuerySelectable;
import org.intermine.pathquery.PathException;
import org.intermine.pathquery.PathQuery;

public class TemplateListAppendService extends TemplateToListService 
{
    public TemplateListAppendService(InterMineAPI im) {
        super(im);
    }

    protected void generateListFromQuery(PathQuery pq, 
        String name, String description,
        Profile profile) throws ObjectStoreException, PathException {
        Query q = MainHelper.makeQuery(
                pq,
                bagManager.getUserAndGlobalBags(profile),
                new HashMap<String, QuerySelectable>(),
                im.getBagQueryRunner(),
                new HashMap<String, BagQueryResult>());

        InterMineBag list = profile.getSavedBags().get(name);
        try {
            list.addToBagFromQuery(q);
        } finally {
            output.addResultItem(Arrays.asList("" + list.size()));
        } 
    }
}