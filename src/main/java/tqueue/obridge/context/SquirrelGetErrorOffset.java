package tqueue.obridge.context;

import java.sql.Timestamp;
import java.sql.Date;
import java.util.List;
import java.math.BigDecimal;
import java.sql.ResultSet;
import tqueue.obridge.objects.*;
import javax.annotation.Generated;

@Generated("org.obridge.generators.ProcedureContextGenerator")
public class SquirrelGetErrorOffset {

    private BigDecimal functionReturn;
    private String query;

    public BigDecimal getFunctionReturn() {
        return this.functionReturn;
    }

    public void setFunctionReturn(BigDecimal functionReturn) {
        this.functionReturn = functionReturn;
    }

    public String getQuery() {
        return this.query;
    }

    public void setQuery(String query) {
        this.query = query;
    }


}
