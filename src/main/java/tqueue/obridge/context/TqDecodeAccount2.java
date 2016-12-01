package tqueue.obridge.context;

import java.sql.Timestamp;
import java.sql.Date;
import java.util.List;
import java.math.BigDecimal;
import java.sql.ResultSet;
import tqueue.obridge.objects.*;
import javax.annotation.Generated;

@Generated("org.obridge.generators.ProcedureContextGenerator")
public class TqDecodeAccount2 {

    private String accountdisplayname;
    private BigDecimal accountid;

    public String getAccountdisplayname() {
        return this.accountdisplayname;
    }

    public void setAccountdisplayname(String accountdisplayname) {
        this.accountdisplayname = accountdisplayname;
    }

    public BigDecimal getAccountid() {
        return this.accountid;
    }

    public void setAccountid(BigDecimal accountid) {
        this.accountid = accountid;
    }


}
