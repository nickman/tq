package tqueue.obridge.context;

import java.sql.Timestamp;
import java.sql.Date;
import java.util.List;
import java.math.BigDecimal;
import java.sql.ResultSet;
import tqueue.obridge.objects.*;
import javax.annotation.Generated;

@Generated("org.obridge.generators.ProcedureContextGenerator")
public class Xlogevent {

    private String msg;
    private BigDecimal errcode;

    public String getMsg() {
        return this.msg;
    }

    public void setMsg(String msg) {
        this.msg = msg;
    }

    public BigDecimal getErrcode() {
        return this.errcode;
    }

    public void setErrcode(BigDecimal errcode) {
        this.errcode = errcode;
    }


}
