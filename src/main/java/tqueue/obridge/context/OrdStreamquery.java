package tqueue.obridge.context;

import java.sql.Timestamp;
import java.sql.Date;
import java.util.List;
import java.math.BigDecimal;
import java.sql.ResultSet;
import tqueue.obridge.objects.*;
import javax.annotation.Generated;

@Generated("org.obridge.generators.ProcedureContextGenerator")
public class OrdStreamquery {

    private ResultSet functionReturn;
    private Integer cnt;

    public ResultSet getFunctionReturn() {
        return this.functionReturn;
    }

    public void setFunctionReturn(ResultSet functionReturn) {
        this.functionReturn = functionReturn;
    }

    public Integer getCnt() {
        return this.cnt;
    }

    public void setCnt(Integer cnt) {
        this.cnt = cnt;
    }


}
