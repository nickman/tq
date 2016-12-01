package tqueue.obridge.context;

import java.sql.Timestamp;
import java.sql.Date;
import java.util.List;
import java.math.BigDecimal;
import java.sql.ResultSet;
import tqueue.obridge.objects.*;
import javax.annotation.Generated;

@Generated("org.obridge.generators.ProcedureContextGenerator")
public class OrdStreamorders {

    private List<Fullorder> functionReturn;
    private Integer cnt;

    public List<Fullorder> getFunctionReturn() {
        return this.functionReturn;
    }

    public void setFunctionReturn(List<Fullorder> functionReturn) {
        this.functionReturn = functionReturn;
    }

    public Integer getCnt() {
        return this.cnt;
    }

    public void setCnt(Integer cnt) {
        this.cnt = cnt;
    }


}
