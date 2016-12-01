package tqueue.obridge.context;

import java.sql.Timestamp;
import java.sql.Date;
import java.util.List;
import java.math.BigDecimal;
import java.sql.ResultSet;
import tqueue.obridge.objects.*;
import javax.annotation.Generated;

@Generated("org.obridge.generators.ProcedureContextGenerator")
public class TqUpdateTrades {

    private List<TqueueObj> trades;

    public List<TqueueObj> getTrades() {
        return this.trades;
    }

    public void setTrades(List<TqueueObj> trades) {
        this.trades = trades;
    }


}
