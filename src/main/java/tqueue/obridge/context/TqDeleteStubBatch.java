package tqueue.obridge.context;

import java.sql.Timestamp;
import java.sql.Date;
import java.util.List;
import java.math.BigDecimal;
import java.sql.ResultSet;
import tqueue.obridge.objects.*;
import javax.annotation.Generated;

@Generated("org.obridge.generators.ProcedureContextGenerator")
public class TqDeleteStubBatch {

    private BigDecimal functionReturn;
    private List<String> xrowids;

    public BigDecimal getFunctionReturn() {
        return this.functionReturn;
    }

    public void setFunctionReturn(BigDecimal functionReturn) {
        this.functionReturn = functionReturn;
    }

    public List<String> getXrowids() {
        return this.xrowids;
    }

    public void setXrowids(List<String> xrowids) {
        this.xrowids = xrowids;
    }


}
