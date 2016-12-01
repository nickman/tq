package tqueue.obridge.context;

import java.sql.Timestamp;
import java.sql.Date;
import java.util.List;
import java.math.BigDecimal;
import java.sql.ResultSet;
import tqueue.obridge.objects.*;
import javax.annotation.Generated;

@Generated("org.obridge.generators.ProcedureContextGenerator")
public class TqParsePipeTradeBatch {

    private List<TqueueObj> functionReturn;
    private String xrowidstr;

    public List<TqueueObj> getFunctionReturn() {
        return this.functionReturn;
    }

    public void setFunctionReturn(List<TqueueObj> functionReturn) {
        this.functionReturn = functionReturn;
    }

    public String getXrowidstr() {
        return this.xrowidstr;
    }

    public void setXrowidstr(String xrowidstr) {
        this.xrowidstr = xrowidstr;
    }


}
